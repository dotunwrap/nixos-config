#!/usr/bin/env bash
# vocab-prune.sh -- remove CJK and Cyrillic vocabulary rows from a HyperQwen int4-head checkpoint
# (a "Latin-only" copy) and verify the result offline. Run it by hand; it does not start, stop or
# benchmark anything.
#
# What "latin-only" means: whole tokens made of Han, kana, Hangul, CJK punctuation or Cyrillic are
# removed. Accented Latin text (Cafe with an accent, Danish, ...), digits, symbols and emoji are kept,
# so this is not ASCII-only and not strictly English. It is also a soft filter: byte-fragment tokens
# stay, so the model can still spell a removed character one byte at a time, and CJK or Cyrillic
# text in a prompt still tokenizes (as many more tokens). Do not rely on it to block those scripts.
#
#   vocab-prune.sh fetch  [default|swift|uncensored|all]  download the served models (default: all)
#   vocab-prune.sh latin-only SRC [DST] [--ban a,b,..]    Latin-only copy of SRC: prune, then verify (alias: english)
#   vocab-prune.sh prune  SRC [DST] [--ban a,b,..] [--dry-run]
#   vocab-prune.sh verify SRC DST
#   vocab-prune.sh all    SRC [DST] [--ban a,b,..]        same as latin-only
#
# fetch runs HyperQwen's own `hyperqwen-setup`, so repos and pinned revisions come from your NixOS config:
#   default     the model step: the fast variant, Qwen3.8-27B-W4A16-AutoRound-fast
#   swift       Swift 1.5, daavidhauser/Swift-1.5-Qwen3.8-27B-W4A16-HyperQwen-INT4
#   uncensored  ultimaterex/Swift-Qwen3.8-27B-Uncensored-W4A16-AutoRound
#   Each step does nothing when its model is already on disk.
#
# SRC / DST are directories, or names under $MODELS. DST defaults to SRC-latin-only
# (SRC-pruned if --ban is changed). Scripts for --ban: han kana hangul cjk_punct cyrillic
# (default: all five). SRC must be in HyperQwen's int4-head layout (both fetched models are).
#
# english / prune / verify are CPU only, and SRC is never modified: unchanged files are
# hardlinked into DST, changed files are written fresh. An existing DST is refused.
# A copy that fails verification is renamed to DST.FAILED-verify (numbered if that name is taken).
#
# Environment: HQ_REPO (HyperQwen checkout, default /home/nia/Projects/HyperQwen)
#              MODELS  (default $HQ_REPO/models)   BAN (default as above)
#              UNIT    (systemd unit to read the FHS wrapper from, default hyperqwen-swift.service)
set -euo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HQ_REPO=${HQ_REPO:-/home/nia/Projects/HyperQwen}
MODELS=${MODELS:-$HQ_REPO/models}
UNIT=${UNIT:-hyperqwen-swift.service}
BAN=${BAN:-han,kana,hangul,cjk_punct,cyrillic}

die() { echo "vocab-prune: $*" >&2; exit 1; }
usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"; }

resolve() {  # an existing directory: a path, or a name under $MODELS
  if [ -d "$1" ]; then (cd "$1" && pwd -P)
  elif [ -d "$MODELS/$1" ]; then (cd "$MODELS/$1" && pwd -P)
  else die "no such model directory: $1"; fi
}

# DST need not exist yet: an absolute path stays, a path with a slash is taken relative to the
# caller's directory, and a bare name goes under $MODELS (the same rule resolve() uses for SRC).
abs_dst() {
  case $1 in
    /*) echo "$1" ;;
    */*) echo "$PWD/$1" ;;
    *) echo "$MODELS/$1" ;;
  esac
}

default_dst() { if [ "$BAN" = "han,kana,hangul,cjk_punct,cyrillic" ]; then echo "$1-latin-only"; else echo "$1-pruned"; fi; }

# The HyperQwen venv's python cannot execute directly on NixOS, so run it inside the FHS wrapper
# the server uses (found from the live systemd unit). CUDA_VISIBLE_DEVICES is emptied: CPU only.
fhs_exec() {  # fhs_exec CMD [ARGS...]
  local fhs tmp rc=0
  fhs=$(python3 -I "$DIR/unit_env.py" "$UNIT")
  tmp=$(mktemp "${TMPDIR:-/tmp}/vocab-prune-fhs.XXXXXX")
  {
    echo '#!/usr/bin/env bash'
    printf 'cd %q\n' "$HQ_REPO"
    printf 'CUDA_VISIBLE_DEVICES= HF_XET_HIGH_PERFORMANCE=1 exec'
    printf ' %q' "$@"
    echo
  } > "$tmp"
  chmod +x "$tmp"
  "$fhs" "$tmp" || rc=$?
  rm -f "$tmp"
  return $rc
}
fhs_python() { fhs_exec "$HQ_REPO/venv/bin/python" "$@"; }

# Downloads are HyperQwen's own `hyperqwen-setup` steps (from the NixOS bundle), so the repos and the
# pinned revisions are the ones your config defines, and a step skips what is already on disk.
cmd_fetch() {
  local steps
  case ${1:-all} in
    default) steps=model ;;
    swift) steps=swift ;;
    uncensored) steps=uncensored ;;
    all) steps=model,swift,uncensored ;;
    *) die "fetch: expected default, swift, uncensored or all (got $1)" ;;
  esac
  command -v hyperqwen-setup > /dev/null || die "hyperqwen-setup not found; is the hyperqwen bundle enabled?"
  echo ">> fetch: hyperqwen-setup, HQ_STEPS=$steps (each step skips what is already downloaded)"
  HQ_STEPS=$steps hyperqwen-setup
}

cmd_prune() {
  local src="" dst="" extra=()
  while [ $# -gt 0 ]; do
    case $1 in
      --ban) BAN=$2; shift 2 ;;
      --dry-run) extra+=(--dry-run); shift ;;
      -*) die "prune: unknown option $1" ;;
      *) if [ -z "$src" ]; then src=$1; elif [ -z "$dst" ]; then dst=$1; else die "prune: too many arguments"; fi; shift ;;
    esac
  done
  [ -n "$src" ] || die "prune: SRC required"
  src=$(resolve "$src")
  [ -n "$dst" ] && dst=$(abs_dst "$dst") || dst=$(default_dst "$src")
  [ "$src" != "$dst" ] || die "DST must differ from SRC"
  # Refuse up front, so that "DST exists" below can only mean this run created it.
  [ ! -e "$dst" ] || [ "${#extra[@]}" -gt 0 ] || die "$dst already exists; remove it or pick another DST"
  echo ">> prune: $src -> $dst  (ban: $BAN)"
  if ! fhs_python "$DIR/prune_vocab.py" "$src" "$dst" --ban "$BAN" "${extra[@]}"; then
    # A failed run leaves a half-built DST; remove it so a rerun is not refused (a dry run builds nothing).
    if [ "${#extra[@]}" -eq 0 ] && [ -d "$dst" ]; then
      echo "vocab-prune: prune failed; removing the partial output $dst" >&2
      rm -rf -- "$dst"
    fi
    return 1
  fi
}

cmd_verify() {
  [ $# -eq 2 ] || die "verify: SRC DST required"
  local src dst; src=$(resolve "$1"); dst=$(resolve "$2")
  echo ">> verify: $dst against $src"
  fhs_python "$DIR/verify_prune.py" "$src" "$dst"
}

cmd_all() {
  local src="" dst=""
  while [ $# -gt 0 ]; do
    case $1 in
      --ban) BAN=$2; shift 2 ;;
      -*) die "all: unknown option $1" ;;
      *) if [ -z "$src" ]; then src=$1; elif [ -z "$dst" ]; then dst=$1; else die "all: too many arguments"; fi; shift ;;
    esac
  done
  [ -n "$src" ] || die "all: SRC required"
  src=$(resolve "$src")
  [ -n "$dst" ] && dst=$(abs_dst "$dst") || dst=$(default_dst "$src")
  cmd_prune "$src" "$dst" --ban "$BAN"
  if ! cmd_verify "$src" "$dst"; then
    # Never leave a checkpoint that failed verification under its real name: a model unit pointing
    # at that name would serve it.
    # Never mv onto an existing directory: that would move the output inside it.
    local failed="$dst.FAILED-verify" n=1
    while [ -e "$failed" ]; do n=$((n + 1)); failed="$dst.FAILED-verify.$n"; done
    mv -- "$dst" "$failed"
    die "verification failed; the output was renamed to $failed so it cannot be served by mistake"
  fi
  echo ">> done: $dst"
}

[ $# -gt 0 ] || { usage; exit 1; }
sub=$1; shift
case $sub in
  fetch) cmd_fetch "$@" ;;
  prune) cmd_prune "$@" ;;
  verify) cmd_verify "$@" ;;
  latin-only|english|all) cmd_all "$@" ;;
  -h|--help|help) usage ;;
  *) usage; die "unknown command: $sub" ;;
esac
