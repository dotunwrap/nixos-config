"""Print the FHS wrapper path from a systemd unit's ExecStart= (so Nix store hashes are never hardcoded).

usage: unit_env.py UNIT
"""
import re, subprocess, sys

unit = sys.argv[1]
text = subprocess.run(["systemctl", "cat", unit], capture_output=True, text=True, check=True).stdout
for line in text.splitlines():
    m = re.match(r"ExecStart=(\S+)\s+\S+", line)
    if m:
        print(m.group(1))
        break
else:
    sys.exit(f"{unit}: no ExecStart= of the form '<fhs wrapper> <start script>'")
