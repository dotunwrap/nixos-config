{
  runCommand,
  nixfmt,
  self,
}:
# runCommand "nixfmt-run-${self.rev or "00000000"}" { } ''
#   ${nixfmt}/bin/nixfmt
# ''
{
}
