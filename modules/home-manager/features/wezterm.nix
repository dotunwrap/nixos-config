{ pkgs, ... }:

{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      return {
        color_scheme = "Catppuccin Frappe",
        front_end = "WebGpu",
        enable_tab_bar = false,
      }
    '';
  };
}
