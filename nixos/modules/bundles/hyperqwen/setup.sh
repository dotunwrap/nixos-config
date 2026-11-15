#!/usr/bin/env bash
# Builds the HyperQwen environment: checkout, venv, model, vLLM patches, pthfa and xgrammar.
# Runs inside hyperqwen-setup-fhs (see default.nix), which provides gcc 15, uv, patch and cmake.
# Every step checks the state it produces, so a second run on a finished install does nothing.
#
# env (set by the hyperqwen-setup wrapper):
#   HQ_REPO     checkout path
#   HQ_REV      commit to check out (empty: leave the checkout alone)
#   HQ_GCC_AR, HQ_GCC_RANLIB   unwrapped gcc 15 binutils wrappers (see the xgrammar step)
# env (optional):
#   HQ_STEPS    comma list from: repo venv deps header model patches pthfa xgrammar dflash kvarn verify
#               (default: everything except dflash and kvarn)
set -euo pipefail

: "${HQ_REPO:?}"
STEPS=${HQ_STEPS:-repo,venv,deps,header,model,patches,pthfa,xgrammar,verify}
want() { case ",$STEPS," in *",$1,"*) return 0 ;; *) return 1 ;; esac }
say() { printf '\n== %s\n' "$*"; }

export TMPDIR=${TMPDIR:-/var/tmp/hyperqwen-setup}
mkdir -p "$TMPDIR"
# nvcc 13.0 rejects gcc 16, so the FHS env carries gcc 15 only.
export CC=/usr/bin/gcc CXX=/usr/bin/g++ CUDAHOSTCXX=/usr/bin/g++ NVCC_CCBIN=/usr/bin/g++

if want repo; then
  say "checkout"
  if [ ! -d "$HQ_REPO/.git" ]; then
    git clone https://github.com/syv-ai/HyperQwen "$HQ_REPO"
  fi
  if [ -n "${HQ_REV:-}" ] && [ "$(git -C "$HQ_REPO" rev-parse HEAD)" != "$HQ_REV" ]; then
    if git -C "$HQ_REPO" diff --quiet HEAD; then
      git -C "$HQ_REPO" fetch -q origin
      git -C "$HQ_REPO" checkout -q "$HQ_REV"
    else
      echo "checkout has local changes; leaving it at $(git -C "$HQ_REPO" rev-parse --short HEAD), not $HQ_REV" >&2
    fi
  fi
fi

cd "$HQ_REPO"
PY=$HQ_REPO/venv/bin/python

if want venv; then
  say "venv"
  [ -x "$PY" ] || uv venv --python 3.12 venv
fi

if want deps; then
  say "python packages"
  have=$("$PY" -m pip show vllm 2>/dev/null | sed -n 's/^Version: //p' || true)
  if [ "$have" = "0.33.0" ]; then
    echo "vllm 0.33.0 already installed"
  else
    uv pip install --python "$PY" pip
    "$PY" -m pip install vllm==0.33.0 huggingface_hub hf_transfer ninja \
      --extra-index-url https://flashinfer.ai/whl/ flashinfer-cubin==0.7.2.post1 pandas \
      nvidia-cuda-nvcc==13.0.88 nvidia-cuda-crt==13.0.88 nvidia-cuda-cccl==13.0.85 nvidia-nvvm==13.0.88
  fi
fi

if want header; then
  say "CUDA header (glibc rsqrt)"
  # glibc 2.42 declares rsqrt/rsqrtf noexcept, and CUDA 13.0's math_functions.h declares them
  # without it, so nvcc rejects pthfa. Give the CUDA declarations the same exception spec.
  "$PY" - <<'PY'
import pathlib, shutil, sys, sysconfig

h = pathlib.Path(sysconfig.get_paths()["purelib"]) / "nvidia/cu13/include/crt/math_functions.h"
if not h.exists():
    sys.exit(f"{h} not found: run the deps step first")
s = h.read_text()
if "__PTHFA_RSQ_EXC" in s:
    print("already patched")
    sys.exit(0)
shutil.copy(h, h.with_name(h.name + ".orig"))
guard = (
    "#if !defined(__PTHFA_RSQ_EXC)\n#if defined(__THROW)\n#define __PTHFA_RSQ_EXC __THROW\n"
    "#else\n#define __PTHFA_RSQ_EXC\n#endif\n#endif\n"
)
dbl = "extern __DEVICE_FUNCTIONS_DECL__ __device_builtin__ double                 rsqrt(double x);"
flt = "extern __DEVICE_FUNCTIONS_DECL__ __device_builtin__ float                  rsqrtf(float x);"
for old in (dbl, flt):
    if s.count(old) != 1:
        sys.exit(f"unexpected header layout, expected one of: {old}")
s = s.replace(dbl, guard + dbl[:-1] + " __PTHFA_RSQ_EXC;")
s = s.replace(flt, flt[:-1] + " __PTHFA_RSQ_EXC;")
h.write_text(s)
print("patched", h)
PY
fi

if want model; then
  say "model"
  M=models/Qwen3.8-27B-W4A16-AutoRound
  # fetch_fast_variant.py is the last step, so its output means the whole chain finished.
  if [ -f "$M-fast/model.safetensors.index.json" ]; then
    echo "$M-fast already built"
  else
    [ -f "$M/config.json" ] || HF_XET_HIGH_PERFORMANCE=1 "$HQ_REPO/venv/bin/hf" download \
      dbirks/Qwen3.8-27B-W4A16-AutoRound --local-dir "$M"
    # These rewrite $M in place. If one fails halfway, delete $M and rerun rather than resuming.
    "$PY" prepare/quant_lm_head.py "$M"
    "$PY" prepare/quant_embed.py "$M"
    "$PY" prepare/quant_mtp.py "$M"
    "$PY" prepare/build_draft_vocab.py "$M" --ids prepare/draft_vocab_ids.json
    "$PY" prepare/fetch_fast_variant.py
  fi
fi

vllm_dir() { "$PY" -c 'import vllm, os; print(os.path.dirname(vllm.__file__))' 2>/dev/null | tail -n1; }

if want patches; then
  say "vLLM patch series"
  bash patches/apply.sh "$(vllm_dir)"
fi

if want pthfa; then
  say "pth-flash-attn"
  PATH=$HQ_REPO/venv/bin:$PATH bash pthfa/install.sh
fi

if want xgrammar; then
  say "xgrammar"
  if "$PY" xgrammar/check.py >/dev/null 2>&1; then
    echo "xgrammar already carries the fix"
  else
    # xgrammar builds with LTO. The Nix-wrapped ar/ranlib can't read GCC's LTO objects, which
    # surfaces as an "undefined symbol" at import, so point cmake at the unwrapped gcc-ar. The
    # build also trips an ODR warning that its -Werror turns into a failure.
    CMAKE_ARGS="-DCMAKE_AR=$HQ_GCC_AR -DCMAKE_RANLIB=$HQ_GCC_RANLIB -DCMAKE_SHARED_LINKER_FLAGS=-Wno-error=odr -DCMAKE_CXX_FLAGS=-Wno-error=odr" \
      PATH=$HQ_REPO/venv/bin:$PATH bash xgrammar/install.sh
  fi
fi

if want dflash; then
  say "DFlash2 drafter"
  "$PY" prepare/fetch_dflash2.py
fi

if want kvarn; then
  say "KVarN"
  PATH=$HQ_REPO/venv/bin:$PATH bash kvarn/install.sh
fi

if want verify; then
  say "verify"
  bash verify.sh --no-server
fi

say "done"
