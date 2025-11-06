#!/usr/bin/env bash

set -e

print_usage() {
  echo "
    Usage: $0 <type> <path> <module>

    DESCRIPTION
      Script to insert a new module for either NixOS or Home Manager.

    EXAMPLES
      $0 nixos programs module
      $0 home programs/shells module
  "
  exit 0
}

if [ -z "$1" ]; then
  print_usage
fi

VALID_TYPES=("nixos" "home")

TYPE="$1"
MODULE_PATH="$2"
MODULE="$3"

if [[ ! " ${VALID_TYPES[*]} " =~ " $TYPE " ]]; then
  print_usage
fi

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"
TEMPLATE_DIR="$SCRIPTS_DIR/../templates"
MODULES_DIR="$SCRIPTS_DIR/../$TYPE/modules"
NEW_MODULE_DIR="$MODULES_DIR/$MODULE_PATH/$MODULE"
MODULE_TEMPLATE="${TEMPLATE_DIR}/$TYPE-module.nix.template"

print_final() {
  echo "
    You can now enable the new module by using config.${MODULE_PATH//\///.}.$MODULE.enable = true;

    Please note that this script assumes that the module exists in nixpkgs but is not already enable-able by default.
  "
}

# Create default.nix for the module
mkdir "$NEW_MODULE_DIR"
cp "$MODULE_TEMPLATE" "$NEW_MODULE_DIR/default.nix"

# Replace template strings
sed -i "s#{{PATH}}#${MODULE_PATH//\//.}#" "$NEW_MODULE_DIR/default.nix"
sed -i "s#{{MODULE}}#$MODULE#" "$NEW_MODULE_DIR/default.nix"
echo "CREATED: $TYPE/modules/$MODULE_PATH/$MODULE/default.nix"

# Add mkEnableOption
grep -q "options\.${MODULE_PATH//\//.} = {" "$MODULES_DIR/$MODULE_PATH/default.nix" || (
  echo "No existing entry for $MODULE_PATH in $MODULES_DIR/default.nix"
  exit 1
)
sed -i "s#options.${MODULE_PATH//\//.} = {#&\n    $MODULE.enable = mkEnableOption \"Enable $MODULE\";#" "$MODULES_DIR/$MODULE_PATH/default.nix"
echo "INSERTED: $TYPE/modules/$MODULE_PATH/default.nix"

# Add to config modules file
grep -q "./$MODULE_PATH;" "$MODULES_DIR/default.nix" || (
  echo "No existing entry for $MODULE_PATH in $MODULES_DIR/default.nix"
  exit 1
)
sed -i "s#\"$MODULE_PATH\" =\ ./$MODULE_PATH;#&\n    \"$MODULE_PATH/$MODULE\" = ./$MODULE_PATH/$MODULE;#" "$MODULES_DIR/default.nix"
echo "INSERTED $TYPE/modules/default.nix"

print_final
