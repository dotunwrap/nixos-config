# PolyStrata (https://github.com/simplexai-labs/PolyStrata): the strata-poly engine (CUDA), its CPU
# picture reader and the Python server, built the way upstream's setup.py does but without it: setup.py
# downloads llama.cpp, pip-installs a venv and compiles into the checkout, none of which a store path
# allows. Model files, the tokenizer pack and the expert profile stay outside the store (see the module).
{
  lib,
  fetchFromGitHub,
  cmake,
  ninja,
  makeWrapper,
  autoAddDriverRunpath,
  cudaPackages_13_0,
  python3,
  # CUDA architectures to compile for. Both of dosei's cards are Ada (sm_89).
  cudaArchitectures ? "89",
  # CPU the experts that stay in RAM run on. Nix drops -march=native, which would leave ggml's CPU
  # kernels without AVX, so name the CPU: dosei's Ryzen 9 7900X is Zen 4 (AVX-512).
  cpuArch ? "znver4",
}:
let
  # setup.py pins CUDA 13.0: 13.2.x miscompiles for sm_120, and the ready-made engine uses 13.0.88.
  cudaPackages = cudaPackages_13_0;
  inherit (cudaPackages) backendStdenv;
  cuda = cudaPackages.cudatoolkit;

  # The two llama.cpp checkouts setup.py downloads: ggml for the engine, mtmd for the picture reader.
  llama = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "3cf03257f219afbe7334045ff7c6a06ac68c627d";
    hash = "sha256-SRGoXa+4ACBCB3eaG9XFYhMN1i0FyPEy9Rrer+dFGYI=";
  };
  llamaVision = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "69f201a2051ea9b9e9b50c3cc56afd9e2ae64414";
    hash = "sha256-r83/Ij5kWZUVh9i7OVWiiP5pS6aD2YyKLJ0i6hMxdyY=";
  };

  python = python3.withPackages (
    ps: with ps; [
      numpy
      jinja2
      regex
      pyyaml
      tqdm
      requests
      pillow
      psutil
    ]
  );
in
backendStdenv.mkDerivation {
  pname = "polystrata";
  version = "0.1.45-poly.7-unstable-2026-11-18";

  src = fetchFromGitHub {
    owner = "simplexai-labs";
    repo = "PolyStrata";
    rev = "3e1642161198c50ff1abed4046f4e4f476099dbb";
    hash = "sha256-rYnExkd+mXEZ4Y26SCT7OLvKaoox+Vcb4dnGQqINw3A=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    makeWrapper
    autoAddDriverRunpath
  ];
  buildInputs = [ cuda ];

  # Two separate CMake projects (the engine at the root, the picture reader in tools/vision).
  dontUseCmakeConfigure = true;

  env = {
    NIX_CFLAGS_COMPILE = "-march=${cpuArch}";
    CUDA_HOME = "${cuda}";
    CUDA_PATH = "${cuda}";
    CUDAToolkit_ROOT = "${cuda}";
    CUDAHOSTCXX = "${backendStdenv.cc}/bin/c++";
  };

  buildPhase = ''
    runHook preBuild

    cmake -S . -B build-poly -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DSTRATA_ENABLE_CUDA=ON \
      -DSTRATA_BUILD_TESTS=OFF \
      -DSTRATA_PORTABLE=OFF \
      -DCMAKE_CUDA_ARCHITECTURES=${cudaArchitectures} \
      -DCMAKE_CUDA_COMPILER=${cuda}/bin/nvcc \
      -DSTRATA_GGML_DIR=${llama}
    cmake --build build-poly --target strata-poly -j $NIX_BUILD_CORES

    # The picture reader runs on the CPU (the cards are under 24 GB, so setup.py picks the CPU too).
    cmake -S tools/vision -B build-vision -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLAMA_DIR=${llamaVision} \
      -DSTRATA_VISION_CUDA=OFF \
      -DSTRATA_PORTABLE=OFF
    cmake --build build-vision --target strata-vision -j $NIX_BUILD_CORES

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    root=$out/share/polystrata
    mkdir -p $root $out/bin
    cp -r serve tools data $root/
    install -Dm755 build-poly/strata-poly $out/bin/strata-poly
    install -Dm755 build-vision/bin/strata-vision $out/bin/strata-vision

    # The server, from the Python environment that has what serve/server.py imports.
    makeWrapper ${python}/bin/python $out/bin/polystrata-server \
      --add-flags "$root/serve/server.py"
    # The tokenizer extractor setup.py runs against a model's GGUF, with the pinned gguf-py.
    makeWrapper ${python}/bin/python $out/bin/polystrata-tokenizer \
      --add-flags "$root/tools/strata_tokenizer.py" \
      --set STRATA_GGUF_PY ${llama}/gguf-py

    runHook postInstall
  '';

  passthru = {
    inherit llama llamaVision python;
  };

  meta = {
    description = "PolyStrata: local LLM server for large mixture-of-experts models (strata-poly engine)";
    homepage = "https://github.com/simplexai-labs/PolyStrata";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "polystrata-server";
  };
}
