{ pkgs }:
pkgs.treefmt.withConfig {
  runtimeInputs = with pkgs; [
    nixfmt
    shfmt
    prettier
  ];

  settings.formatter = {
    nixfmt = {
      command = "nixfmt";
      includes = [ "*.nix" ];
    };

    shfmt = {
      command = "shfmt";
      options = [
        "-i"
        "2"
        "-w"
      ];
      includes = [
        "*.sh"
        ".envrc"
      ];
    };

    prettier = {
      command = "prettier";
      options = [ "--write" ];
      includes = [
        "*.yaml"
        "*.yml"
        "*.json"
        "*.md"
        "*.markdown"
      ];
    };
  };
}
