{
  runCommand,
  nixfmt,
  self,
}:
runCommand "check-nixfmt-${self.rev or "dirty"}" { } ''
  ${nixfmt}/bin/nixfmt --check ${self} < /dev/null | tee $out
''
