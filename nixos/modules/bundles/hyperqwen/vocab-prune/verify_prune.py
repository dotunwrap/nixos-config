"""Offline checks for a pruned checkpoint (no GPU, no server).

usage: verify_prune.py SRC DST

Checks, in order:
  - the source is untouched (vocab_size unchanged) and DST has the new vocab_size
  - lm_head / embed_tokens: new row count, and 2000 random rows (+ the edges) are byte-identical to their source rows
  - the draft head matches the new lm_head rows for its ids; ids are unique and in range
  - tokenizer: text with no removed scripts tokenizes identically once new ids are mapped back to old ones
  - text in the removed scripts still round-trips (through byte tokens)
  - special-token ids agree between tokenizer.json and config.json / generation_config.json
Exits non-zero on the first failure; prints VERIFY OK at the end.
"""
import json, random, sys

import torch
from safetensors import safe_open
from tokenizers import Tokenizer

src, dst = sys.argv[1].rstrip("/"), sys.argv[2].rstrip("/")
meta = json.load(open(dst + "/vocab_prune.json"))
keep = meta["kept_old_ids"]
row_src = keep + meta["padding_old_rows"]
n_total = meta["n_rows"]


def fail(msg):
    sys.exit("VERIFY FAILED: " + msg)


c_src = json.load(open(src + "/config.json"))
c_dst = json.load(open(dst + "/config.json"))
v_src, v_dst = c_src["text_config"]["vocab_size"], c_dst["text_config"]["vocab_size"]
print(f"vocab_size {v_src} -> {v_dst}")
if v_dst != n_total or v_dst >= v_src:
    fail("vocab_size in the output config is wrong")

sidx = json.load(open(src + "/model.safetensors.index.json"))["weight_map"]
didx = json.load(open(dst + "/model.safetensors.index.json"))["weight_map"]
random.seed(0)
for prefix in ("lm_head", "model.language_model.embed_tokens"):
    with safe_open(f"{src}/{sidx[prefix + '.weight_packed']}", framework="pt") as a, \
         safe_open(f"{dst}/{didx[prefix + '.weight_packed']}", framework="pt") as b:
        for part in ("weight_packed", "weight_scale"):
            sa, sb = a.get_slice(f"{prefix}.{part}").get_shape(), b.get_slice(f"{prefix}.{part}").get_shape()
            print(prefix, part, sa, "->", sb)
            if sb[0] != n_total or sb[1:] != sa[1:]:
                fail(f"{prefix}.{part} has the wrong shape")
        pa, pb = a.get_tensor(prefix + ".weight_packed"), b.get_tensor(prefix + ".weight_packed")
        sa_, sb_ = a.get_tensor(prefix + ".weight_scale"), b.get_tensor(prefix + ".weight_scale")
        rows = random.sample(range(n_total), min(2000, n_total)) + [0, n_total - 1, len(keep) - 1, len(keep)]
        for j in rows:
            if not (torch.equal(pb[j], pa[row_src[j]]) and torch.equal(sb_[j], sa_[row_src[j]])):
                fail(f"{prefix} row {j} does not match source row {row_src[j]}")
        shape = b.get_tensor(prefix + ".weight_shape").tolist()
        if shape[0] != n_total:
            fail(f"{prefix}.weight_shape says {shape}")
print("head and embedding rows match the source")

ids = torch.load(dst + "/mtp_draft_vocab_ids.pt")
with safe_open(f"{dst}/{didx['mtp.draft_lm_head.weight_packed']}", framework="pt") as b:
    dp = b.get_tensor("mtp.draft_lm_head.weight_packed")
with safe_open(f"{dst}/{didx['lm_head.weight_packed']}", framework="pt") as h:
    hp = h.get_tensor("lm_head.weight_packed")
if not (dp.shape[0] == ids.numel() == len(set(ids.tolist())) and int(ids.max()) < n_total):
    fail("draft ids are duplicated, out of range, or do not match the draft head rows")
if not torch.equal(dp, hp.index_select(0, ids)):
    fail("draft head rows differ from the new lm_head rows for the same ids")
print(f"draft head: {dp.shape[0]} rows, matches the new lm_head")

ta, tb = Tokenizer.from_file(src + "/tokenizer.json"), Tokenizer.from_file(dst + "/tokenizer.json")
new_to_old = dict(enumerate(keep))
samples = [
    "The quick brown fox jumps over the lazy dog. 12345 + 67890 = 80235.",
    "def f(x):\n    return [i**2 for i in range(x) if i % 2 == 0]  # squares\n",
    "Café naïve résumé — “quoted” text… with ümlauts and åäö, Ærø, İstanbul.",
    "<|im_start|>user\nhello<|im_end|>\n<|im_start|>assistant\n<think>\n</think>\n",
    "Emoji: \U0001F600 \U0001F680 and symbols ± × ÷ → ≤ ≥ €£¥.",
    "Dansk: Blåbærgrød med fløde — på tirsdag. Ærlig talt!",
]
bad = 0
for s in samples:
    ia, ib = ta.encode(s).ids, tb.encode(s).ids
    ok = [new_to_old[i] for i in ib] == ia
    bad += not ok
    print("OK  " if ok else "DIFF", len(ia), len(ib), repr(s[:40]))
if bad:
    fail(f"{bad} kept-text samples tokenize differently")

for s in ("你好，世界！这是一个测试。",
          "Привет, мир! Это тест.",
          "こんにちは世界 안녕하세요"):
    ib = tb.encode(s).ids
    if tb.decode(ib) != s or max(ib) >= n_total:
        fail(f"removed-script text does not round-trip: {s!r}")
    print("round-trip OK, tokens", len(ta.encode(s).ids), "->", len(ib))

g = json.load(open(dst + "/generation_config.json"))
tid = tb.token_to_id
checks = [
    (tid("<|im_end|>") in g["eos_token_id"], "eos_token_id"),
    (tid("<|endoftext|>") == g["pad_token_id"], "pad_token_id"),
    (tid("<|image_pad|>") == c_dst["image_token_id"], "image_token_id"),
    (tid("<|video_pad|>") == c_dst["video_token_id"], "video_token_id"),
    (tid("<|vision_start|>") == c_dst["vision_start_token_id"], "vision_start_token_id"),
    (tid("<|vision_end|>") == c_dst["vision_end_token_id"], "vision_end_token_id"),
]
for ok, name in checks:
    if not ok:
        fail(f"{name} does not match the tokenizer")
print("special token ids consistent")

# No small JSON file may still carry an old special-token id: those ids are now out of range, and
# a missed field (a different export can keep ids somewhere the script does not know about) would
# silently point at the wrong token.
old_special = {a["id"] for a in json.load(open(src + "/tokenizer.json"))["added_tokens"]}


def ints(o):
    if isinstance(o, dict):
        for v in o.values():
            yield from ints(v)
    elif isinstance(o, list):
        for v in o:
            yield from ints(v)
    elif isinstance(o, int) and not isinstance(o, bool):
        yield o


for name in ("config.json", "generation_config.json", "tokenizer_config.json",
             "processor_config.json", "preprocessor_config.json", "video_preprocessor_config.json"):
    try:
        stale = sorted(set(ints(json.load(open(f"{dst}/{name}")))) & old_special)
    except FileNotFoundError:
        continue
    if stale:
        fail(f"{name} still contains old special-token ids {stale}")
print("no stale special-token ids in the config files")
print("VERIFY OK")
