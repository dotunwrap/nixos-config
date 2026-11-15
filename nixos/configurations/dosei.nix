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
    "hyperqwen"
  ];

  # 160k context with vision and MTP on 28GB. UD-Q4_K_XL plus ~7.2GB of KV cache (~45KB per
  # token) leaves ~1GB spare per card at the default 512 ubatch. The vision projector runs on the CPU (~2.5s per image) to spare
  # GPU 0, which also drives the desktop. MTP is on by default for the default model.
  bundles.local_LLM = {
    model = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";
    # Reachable over Tailscale only: the firewall opens no public ports and trusts tailscale0.
    host = "0.0.0.0";
    contextSize = 163840;
    tensorSplit = "15,12";
    vision = true;
    mmprojOffload = false;

    # Used instead when no display is connected to the NVIDIA cards (picked at server
    # start): nothing is drawing on GPU 0, so the context grows by 1.5x (~+2.9GB of KV
    # cache). The projector stays on the CPU like the connected profile. Untested
    # headroom; raise cautiously.
    headless = {
      contextSize = 196608;
    };

    # Abliterated Qwen3.8-27B (Heretic) with Unsloth dynamic quants. Loaded on request;
    # only one model is resident at a time. Sampling follows the model card.
    modelSettings."outsourc-e/Qwen3.8-27B-Unleashed-GGUF:UD-Q4_K_M" = {
      hf-repo = "outsourc-e/Qwen3.8-27B-Unleashed-GGUF:UD-Q4_K_M";
      spec-type = "draft-mtp";
      spec-draft-n-max = 2;
      reasoning-effort = "xhigh";
      temp = 1.0;
      top-p = 0.95;
      top-k = 20;
    };
  };

  # HyperQwen (patched vLLM) serves the same Qwen3.8-27B at about 100 tok/s decode with MTP and
  # a 150k context on this pair, against about 83 tok/s from llama.cpp's MTP. It starts at boot
  # and takes llama-cpp's place; llama-cpp stays defined and `systemctl start llama-cpp` swaps back.
  # Vision runs with the tower's weights in host RAM, so images work as they do with llama.cpp
  # (one image per request).
  bundles.hyperqwen = {
    vision = true;
    # Hermes picks between the base model and Swift 1.5 through llama-swap on :18020.
    router.enable = true;
    gpuMemoryUtilization = "0.95";
    # Reachable over Tailscale only, like llama-cpp: the firewall opens no public ports and
    # trusts tailscale0. There is no API key.
    host = "0.0.0.0";
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
