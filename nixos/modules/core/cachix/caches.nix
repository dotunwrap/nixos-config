let
  dir = ./caches;
  entries = builtins.readDir dir;
  isCacheFile = name: entries.${name} == "regular" && builtins.match ".*\\.nix" name != null;
in
builtins.map (name: import (dir + "/${name}")) (
  builtins.filter isCacheFile (builtins.attrNames entries)
)
