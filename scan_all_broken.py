"""
Find ALL remaining broken ? symbols in LabaFlow.html
that should be emojis, arrows, or peso signs.
Outputs a full report organized by section.
"""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

in_script = False
in_style  = False
results   = []

for i, raw in enumerate(lines, 1):
    line = raw.rstrip('\n')
    stripped = line.strip()

    if re.search(r'<script[\s>]', line):  in_script = True
    if '</script>' in line:               in_script = False
    if '<style' in line:                  in_style  = True
    if '</style>' in line:                in_style  = False

    # Scan HTML content only (not script/style)
    if in_script or in_style:
        continue

    # Skip pure HTML comments
    if stripped.startswith('<!--'):
        continue

    # Find lines with ? that look broken
    # A broken ? is one that:
    # 1. Appears between > < (inside HTML text)
    # 2. Appears in attribute values that aren't hrefs/queries
    # 3. Is NOT a real question mark in sentences (followed by <, space+sentence, etc.)

    # Pattern 1: HTML text content with leading ?
    matches = re.findall(r'>([^<]*\?[^<]*)<', line)
    for m in matches:
        m = m.strip()
        if not m: continue
        # Skip real question marks (FAQ questions, "Got Questions?", etc.)
        if re.search(r'\w\?(\s*$|\s*<)', m): continue
        # Skip URL query strings
        if '=' in m and '&' in m: continue
        # These look broken
        if re.search(r'^\?|[^a-zA-Z\s]\?|^\?\?', m.strip()):
            results.append((i, 'HTML', stripped[:150]))
            break

    # Pattern 2: JS template strings with broken ?
    if in_script and re.search(r'[`\'"][^`\'"]*\?[^`\'"]*[`\'"]', line):
        if re.search(r'\?\?|\?[A-Z]|[^\w]\?[^\w\s?!]', line):
            results.append((i, 'JS', stripped[:150]))

# Also scan script blocks for broken ? in template literals
in_script2 = False
for i, raw in enumerate(lines, 1):
    line = raw.rstrip('\n')
    if re.search(r'<script[\s>]', line):  in_script2 = True
    if '</script>' in line:               in_script2 = False
    if not in_script2: continue

    # Look for ? in template literal strings that should be emojis
    # Patterns: ni:'?', icon:'?', `...?...`, '??'
    if re.search(r"ni:'[^']*\?|icon:'[^']*\?|'[^']*\?\?[^']*'|`[^`]*\?\?[^`]*`", line):
        results.append((i, 'JS-ni/icon', line.strip()[:150]))

print(f"Found {len(results)} lines with broken symbols:\n")
prev_section = ""
for ln, typ, txt in sorted(set(results)):
    # Determine section
    sec = "HTML" if typ == "HTML" else "JS"
    if sec != prev_section:
        print(f"\n--- {sec} content ---")
        prev_section = sec
    print(f"  Line {ln:5d}: {txt[:130]}")
