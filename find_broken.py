"""Find all remaining ? that should be emojis or symbols in HTML content."""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Only look in HTML content (outside script/style tags)
in_script = False
in_style  = False
results   = []

for i, line in enumerate(lines, 1):
    stripped = line.strip()

    if re.search(r'<script[\s>]', line):  in_script = True
    if '</script>' in line:               in_script = False
    if '<style' in line:                  in_style  = True
    if '</style>' in line:                in_style  = False

    if in_script or in_style:
        continue

    # Find ? that look broken: surrounded by letters/tags or at start of text content
    # Skip ternary ? in onclick="" attributes
    # Pattern: > then whitespace then ? — this is HTML text content
    if re.search(r'>[^<]*\?[^<]*<', line) or re.search(r'>[^<]*\?\?[^<]*<', line):
        # Skip if it's clearly a URL query string
        if 'http' in line or 'href' in line:
            continue
        # Skip if the ? is followed by a digit (price like ?180)
        if re.search(r'\?\d', line):
            results.append((i, 'PRICE', stripped[:120]))
            continue
        results.append((i, 'EMOJI?', stripped[:120]))

print(f"Found {len(results)} lines with potential broken content:\n")
for ln, typ, txt in results[:60]:
    print(f"  Line {ln:5d} [{typ}]: {txt}")
