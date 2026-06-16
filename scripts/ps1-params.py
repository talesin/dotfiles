#!/usr/bin/env python3
"""Extract parameter names from a PowerShell script's param() block."""
import sys
import re

if len(sys.argv) < 2:
    sys.exit(0)

try:
    content = open(sys.argv[1]).read()
except OSError:
    sys.exit(0)

m = re.search(r'[Pp]aram\s*\(', content)
if not m:
    sys.exit(0)

# Walk forward tracking paren depth to find the matching closing paren
start = m.end()
depth = 1
i = start
while i < len(content) and depth > 0:
    c = content[i]
    if c == '(':
        depth += 1
    elif c == ')':
        depth -= 1
    i += 1

param_block = content[start:i - 1]
seen = set()
for name in re.findall(r'\$([A-Za-z][A-Za-z0-9_]*)', param_block):
    if name not in seen:
        seen.add(name)
        print('-' + name)
