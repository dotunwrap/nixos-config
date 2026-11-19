"""Remove whole-token CJK / Cyrillic rows from a HyperQwen W4A16 checkpoint.

Writes a NEW model directory; the source is never modified (unchanged files are
hardlinked, changed files are written fresh).

What changes
  - lm_head / embed_tokens rows (packed int32 + per-row scales + weight_shape)
  - mtp.draft_lm_head rows and mtp_draft_vocab_ids.pt (ids remapped)
  - tokenizer.json (vocab ids remapped, merges touching removed tokens dropped)
  - tokenizer_config.json added_tokens_decoder keys
  - config.json / generation_config.json special-token ids and vocab_size
  - vocab_prune.json (the kept old ids; new id == index) for audit

Caveat: only whole-UTF-8 tokens are removed. Byte-fragment tokens stay, so the
model can in principle still spell a banned character one byte at a time, and banned
text in a prompt still tokenizes (into many more tokens). It is a soft filter.
The default ban (han, kana, hangul, cjk_punct, cyrillic) keeps accented Latin text, so
the result is "Latin-only", not ASCII-only.

Normally run through vocab-prune.sh, which supplies the FHS env (CPU only).
"""
import argparse, json, os, shutil, sys

import torch
from safetensors import safe_open
from safetensors.torch import save_file

SCRIPTS = {
    "han":       [(0x3400, 0x4DBF), (0x4E00, 0x9FFF), (0xF900, 0xFAFF), (0x20000, 0x2FA1F)],
    "kana":      [(0x3040, 0x30FF), (0x31F0, 0x31FF), (0xFF66, 0xFF9F)],
    "hangul":    [(0x1100, 0x11FF), (0x3130, 0x318F), (0xAC00, 0xD7AF)],
    "cjk_punct": [(0x3000, 0x303F), (0xFF00, 0xFF65), (0xFFA0, 0xFFEF)],
    "cyrillic":  [(0x0400, 0x04FF), (0x0500, 0x052F), (0x1C80, 0x1C8F), (0x2DE0, 0x2DFF), (0xA640, 0xA69F)],
}
DEFAULT_BAN = ["han", "kana", "hangul", "cjk_punct", "cyrillic"]
ALIGN = 64  # vLLM pads vocab-parallel heads to this; the source checkpoint is already aligned

ap = argparse.ArgumentParser()
ap.add_argument("src")
ap.add_argument("dst")
ap.add_argument("--ban", default=",".join(DEFAULT_BAN))
ap.add_argument("--dry-run", action="store_true")
args = ap.parse_args()
src, dst = args.src.rstrip("/"), args.dst.rstrip("/")
ban = set(args.ban.split(","))
assert ban <= set(SCRIPTS), f"unknown script in {ban}"


def scripts_of(ch):
    c = ord(ch)
    return {n for n in ban if any(a <= c <= b for a, b in SCRIPTS[n])}


def bytes_to_unicode():
    bs = list(range(33, 127)) + list(range(161, 173)) + list(range(174, 256))
    cs = bs[:]
    n = 0
    for b in range(256):
        if b not in bs:
            bs.append(b)
            cs.append(256 + n)
            n += 1
    return {chr(c): b for b, c in zip(bs, cs)}


u2b = bytes_to_unicode()

# ---- decide what to remove ---------------------------------------------------------
tok = json.load(open(src + "/tokenizer.json"))
vocab = tok["model"]["vocab"]
added = {a["id"]: a for a in tok["added_tokens"]}
n_real = max(max(vocab.values()), max(added)) + 1  # 248077
cfg = json.load(open(src + "/config.json"))
V = cfg["text_config"]["vocab_size"]  # 248320, includes padding rows
assert n_real <= V

# ---- preflight: this tool slices already-quantized heads, so refuse anything else early ----
_idx = json.load(open(src + "/model.safetensors.index.json"))["weight_map"]
_need = ["lm_head.weight_packed", "lm_head.weight_scale", "lm_head.weight_shape",
         "model.language_model.embed_tokens.weight_packed", "model.language_model.embed_tokens.weight_scale",
         "model.language_model.embed_tokens.weight_shape", "mtp.draft_lm_head.weight_packed",
         "mtp.draft_lm_head.weight_scale", "mtp.draft_lm_head.weight_shape"]
_missing = [k for k in _need if k not in _idx]
if _missing or not os.path.exists(src + "/mtp_draft_vocab_ids.pt") or tok["model"].get("type") != "BPE":
    sys.exit("preflight: not a HyperQwen int4-head checkpoint (needs requantized lm_head/embed_tokens, a draft head, "
             "mtp_draft_vocab_ids.pt and a BPE tokenizer.json).\n  missing tensors: %s\n"
             "  Run HyperQwen's prepare/quant_lm_head.py, quant_embed.py and build_draft_vocab.py first (docs/install.md)."
             % (_missing or "none"))

banned = set()
for piece, i in vocab.items():
    if i in added:
        continue
    try:
        raw = bytes(u2b[c] for c in piece)
        txt = raw.decode("utf-8")
    except (KeyError, UnicodeDecodeError):
        continue  # fragment: kept
    if any(scripts_of(ch) for ch in txt):
        banned.add(i)

keep = [i for i in range(n_real) if i not in banned]
n_keep = len(keep)
n_total = -(-n_keep // ALIGN) * ALIGN
pad_rows = list(range(n_real, n_real + (n_total - n_keep)))
assert pad_rows[-1] < V if pad_rows else True
row_src = keep + pad_rows  # old row index for each new row
new_id = {old: new for new, old in enumerate(keep)}
print(f"banned {len(banned)} of {n_real} tokens; keep {n_keep}; new rows {n_total} (+{len(pad_rows)} padding); was {V}")

draft_ids = torch.load(src + "/mtp_draft_vocab_ids.pt").tolist()
d_keep = [i for i in draft_ids if i in new_id]
in_draft = set(d_keep)
# pad the draft head to the alignment with the lowest kept ids it doesn't already hold
d_need = -(-len(d_keep) // ALIGN) * ALIGN - len(d_keep)
d_extra = [i for i in keep if i not in in_draft][:d_need]
d_old = d_keep + d_extra
print(f"draft head {len(draft_ids)} -> {len(d_old)} rows ({len(draft_ids) - len(d_keep)} dropped, {len(d_extra)} alignment rows added)")

if args.dry_run:
    sys.exit(0)

# ---- output tree: hardlink everything, then replace what changes -------------------
assert not os.path.exists(dst), f"{dst} already exists"
for root, _, files in os.walk(src):
    rel = os.path.relpath(root, src)
    os.makedirs(os.path.join(dst, rel), exist_ok=True)
    for f in files:
        s, d = os.path.join(root, f), os.path.join(dst, rel, f)
        try:
            os.link(s, d)
        except OSError:
            shutil.copy2(s, d)


def fresh(name):
    p = os.path.join(dst, name)
    if os.path.exists(p):
        os.unlink(p)  # break the hardlink before writing; the source stays intact
    return p


# ---- tensors -----------------------------------------------------------------------
idx = json.load(open(src + "/model.safetensors.index.json"))["weight_map"]
rows_t = torch.tensor(row_src, dtype=torch.int64)


_pending = {}  # shard -> edits. Applied together in flush(): two tensors can share one shard
               # (lm_head and embed_tokens do in some exports), and editing them in separate passes
               # would have the second pass start from the source shard and discard the first edit.


def rewrite(shard, edit):
    _pending.setdefault(shard, []).append(edit)


def flush():
    for shard, edits in _pending.items():
        tensors, meta = {}, None
        with safe_open(f"{src}/{shard}", framework="pt") as h:
            meta = h.metadata()
            for k in h.keys():
                tensors[k] = h.get_tensor(k)
        for edit in edits:
            edit(tensors)
        save_file(tensors, fresh(shard), metadata=meta or {"format": "pt"})
    _pending.clear()


def slice_head(prefix, n_rows, rows):
    def edit(t):
        for part in ("weight_packed", "weight_scale"):
            t[f"{prefix}.{part}"] = t[f"{prefix}.{part}"].index_select(0, rows).contiguous()
        shape = t[f"{prefix}.weight_shape"]
        t[f"{prefix}.weight_shape"] = torch.tensor([n_rows, int(shape[1])], dtype=shape.dtype)
    return edit


head, embed = "lm_head", "model.language_model.embed_tokens"
rewrite(idx[head + ".weight_packed"], slice_head(head, n_total, rows_t))
rewrite(idx[embed + ".weight_packed"], slice_head(embed, n_total, rows_t))

# the draft head is rows of the (original) lm_head selected by id, so rebuild it from
# the source head: that also lets alignment rows be added
with safe_open(f"{src}/{idx[head + '.weight_packed']}", framework="pt") as h:
    full_p, full_s = h.get_tensor(head + ".weight_packed"), h.get_tensor(head + ".weight_scale")
d_rows = torch.tensor(d_old, dtype=torch.int64)


def edit_extra(t):
    old = t["mtp.draft_lm_head.weight_shape"]
    t["mtp.draft_lm_head.weight_packed"] = full_p.index_select(0, d_rows).contiguous()
    t["mtp.draft_lm_head.weight_scale"] = full_s.index_select(0, d_rows).contiguous()
    t["mtp.draft_lm_head.weight_shape"] = torch.tensor([len(d_old), int(old[1])], dtype=old.dtype)


rewrite(idx["mtp.draft_lm_head.weight_packed"], edit_extra)
flush()
torch.save(torch.tensor([new_id[i] for i in d_old], dtype=torch.int64), fresh("mtp_draft_vocab_ids.pt"))

# ---- tokenizer ---------------------------------------------------------------------
kept_pieces = {}
new_vocab = {}
for piece, i in vocab.items():
    if i in new_id:
        new_vocab[piece] = new_id[i]
merges_old = tok["model"]["merges"]
merges = []
for m in merges_old:
    a, b = m.split(" ") if isinstance(m, str) else m
    if a in new_vocab and b in new_vocab and (a + b) in new_vocab:
        merges.append(m)
print(f"merges {len(merges_old)} -> {len(merges)}")
tok["model"]["vocab"] = new_vocab
tok["model"]["merges"] = merges
for a in tok["added_tokens"]:
    a["id"] = new_id[a["id"]]
json.dump(tok, open(fresh("tokenizer.json"), "w"), ensure_ascii=False)

tc = json.load(open(src + "/tokenizer_config.json"))
if "added_tokens_decoder" in tc:  # some exports name special tokens only; nothing to remap then
    tc["added_tokens_decoder"] = {str(new_id[int(k)]): v for k, v in tc["added_tokens_decoder"].items()}
    json.dump(tc, open(fresh("tokenizer_config.json"), "w"), ensure_ascii=False, indent=2)
else:
    print("tokenizer_config.json has no added_tokens_decoder; left as is")

# ---- configs -----------------------------------------------------------------------
special = set(added)


def remap(o, path=""):
    if isinstance(o, dict):
        for k, v in o.items():
            if k.endswith("token_id") and isinstance(v, int) and v in special:
                o[k] = new_id[v]
                print("  ", path + "/" + k, v, "->", o[k])
            elif k.endswith(("token_id", "token_ids")) and isinstance(v, list):
                o[k] = [new_id[x] if x in special else x for x in v]
                print("  ", path + "/" + k, v, "->", o[k])
            else:
                remap(v, path + "/" + k)
    elif isinstance(o, list):
        for x in o:
            remap(x, path)


skip = cfg.pop("quantization_config", None)  # no ids in there; keep it byte-identical
remap(cfg)
cfg["text_config"]["vocab_size"] = n_total
if skip is not None:
    cfg["quantization_config"] = skip
json.dump(cfg, open(fresh("config.json"), "w"), indent=2, ensure_ascii=False)

gen = json.load(open(src + "/generation_config.json"))
remap(gen)
json.dump(gen, open(fresh("generation_config.json"), "w"), indent=2)

json.dump({"banned_scripts": sorted(ban), "source": src, "n_rows": n_total, "n_real": n_keep,
           "kept_old_ids": keep, "padding_old_rows": pad_rows},
          open(os.path.join(dst, "vocab_prune.json"), "w"))
print("wrote", dst)
