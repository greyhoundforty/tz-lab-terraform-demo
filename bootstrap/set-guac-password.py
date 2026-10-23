#!/usr/bin/env python3
"""Set the Guacamole student password in the on-server user mapping."""

import os
import pathlib
import re
import subprocess
import sys

password = sys.stdin.read()
if not password or any(character in password for character in "\"<&\n"):
    raise SystemExit("password is empty or contains characters that would break the user mapping")

path = pathlib.Path("/opt/lab/guacamole/user-mapping.xml")
text = path.read_text()
new, count = re.subn(
    r'(<authorize username="student" password=")[^"]*(")',
    lambda match: match.group(1) + password + match.group(2),
    text,
    count=1,
)
if count != 1:
    raise SystemExit("student authorize entry not found in user-mapping.xml")

path.write_text(new)
os.chown(path, 1001, 1001)
os.chmod(path, 0o600)
subprocess.run(
    ["docker", "compose", "-f", "/opt/lab/guacamole/compose.yaml", "restart", "guacamole"],
    check=True,
)
