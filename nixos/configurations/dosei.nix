_:
{
  config,
  pkgs,
  ...
}:

{
  activeBundles = [
    "base"
    "development"
    "niri"
    "gaming"
    "local_LLM"
  ];

  bundles.local_LLM = {
    # HyperQwen is on by default; Strata joins the router as `strata-flash`, started on request.
    strata = {
      enable = true;
      coder.enable = true;
      swift.enable = true;
    };
    # ExLlamaV3 via TabbyAPI, experts split between the cards and RAM, as `exl3-flash`.
    tabbyapi.enable = true;
    # Pi picks between the models through llama-swap on :18020.
    router.enable = true;
    # Reachable over Tailscale only: the firewall opens no public ports and trusts tailscale0.
    # There is no API key.
    host = "0.0.0.0";

    # HyperQwen (patched vLLM) serves Qwen3.8-27B at about 100 tok/s decode with MTP and a 150k
    # context on this pair. It starts at boot behind the router. Vision runs with the tower's
    # weights in host RAM (one image per request).
    hyperqwen = {
      vision = true;
      gpuMemoryUtilization = "0.93";
      extraEnvironment = {
        # int8 activations (W4A8 Marlin) for faster prefill, on every linear layer (the launcher's own
        # default for INT8_LAYERS, written out here so a launcher change cannot alter it). Decode is
        # unchanged. Prefill at 16k went 1,320 to 1,766 tok/s (+34%) with NCCL_PROTO unset, and 930 to
        # 1,140 (+22%) with the old NCCL_PROTO=LL.
        # Quality cost: it raises perplexity. On Swift it measured 8.27 to 8.37 (+1.2%; code 3.82 to 3.87).
        # The docs measured +3.7% to +4.1% on the base checkpoint, and fewer layers cost less (gate/up
        # only +0.9%, whole MLP +2.2%; INT8_LAYERS=gate_up or mlp). Tool calls (10/10) and 100k needles
        # were unaffected. A coding pass/fail eval was not run.
        INT8_ACT = "int8";
        INT8_LAYERS = "mlp|linear_attn|self_attn";
        # Keeps the quantized token embedding in pinned host RAM instead of VRAM. On this pair it freed
        # about 0.6 GiB per rank (KV pool 169,306 to 201,980 tokens at 0.93) with identical ms per pass.
        # The 12 GB card sets the pool size, so it gains the most. Costs host RAM and boot time.
        EMBED_UVA = "1";
        # The launcher caps images at one per prompt with VISION=1. EXTRA_ARGS comes last on the
        # vLLM command line, so this raises it to eight. It replaces the module's own EXTRA_ARGS, so
        # the tensor-parallel flag is repeated. The JSON must have no spaces: the launcher word-splits
        # EXTRA_ARGS. vLLM profiles the encoder at the largest accepted request, so a higher count
        # shrinks the KV pool. --chat-template replaces the model directory's template with the Qwen
        # Sharp one (froggeric v22.4 plus a terseness prompt, off per request with
        # chat_template_kwargs {"terse": false}); the file lives in the HyperQwen checkout.
        EXTRA_ARGS = "--tensor-parallel-size ${toString config.bundles.local_LLM.hyperqwen.tensorParallelSize} --limit-mm-per-prompt {\"image\":{\"count\":8}} --chat-template ${config.bundles.local_LLM.hyperqwen.repoPath}/templates/sharp/chat_template.jinja";
      };
    };
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = false;
        finegrained = false;
      };
      open = true;
      nvidiaSettings = true;
    };
  };

  boot.kernelModules = [
    "kvm-amd"
  ];

  # NOTE: Despite this host not using X11, hardware.nvidia is gated on this being set.
  services.xserver.videoDrivers = [ "nvidia" ];

  networking = {
    hostName = "dosei";
    networkmanager.enable = true;
    nftables.enable = true;
    firewall = {
      enable = true;

      trustedInterfaces = [ config.services.tailscale.interfaceName ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };

  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  time.timeZone = "America/New_York";

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  nix.package = pkgs.nix;

  users.users = import ./users/nia.nix pkgs;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
