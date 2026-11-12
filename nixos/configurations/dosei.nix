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

  # Extra router models. The repo ships regular and MTP GGUFs side by side, so pin the
  # exact file instead of relying on the quant tag. Q4_K_M (18.5GB) is the largest that fits at 128k (Q5_K_M, 21GB, OOMs GPU0);
  # the author warns tool calling degrades below Q4_K_M.
  bundles.local_LLM.modelSettings."turbo-fable-coder" = {
    hf-repo = "DavidAU/Qwen3.8-27B-TURBO-Fable-Cold-Fusion-735-882-Heretic-Uncensored-NEO-CODER-MAX-MTP-GGUF";
    hf-file = "Qwen3.8-27B-TurboFCFusion-735-882-Here-Uncen-NEO-CODER-MAX-MTP-Q4_K_M.gguf";
    # Heavier than the default quant: shave GPU0, which also drives the desktop
    tensor-split = "15,12";
    # +32k over the global 128k: ~1.1GB more KV cache, split across both GPUs
    ctx-size = 163840;
    spec-type = "draft-mtp";
    spec-draft-n-max = 2;
    reasoning-effort = "xhigh";
    # Author recommends temp 0.6-0.7 and no repetition penalty
    temp = 0.6;
    top-p = 0.95;
    top-k = 20;
    repeat-penalty = 1;
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
