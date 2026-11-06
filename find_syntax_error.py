"""
Find JavaScript syntax errors in LabaFlow.html by checking
brace/bracket balance and finding stray characters.
"""
path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'

with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()
    content = f.read() if False else ''.join(lines)

# Extract all <script> content (non-module)
import re

# Find all script blocks
scripts = []
for m in re.finditer(r'<script(?![^>]*type=["\']module["\'])[^>]*>(.*?)</script>', content, re.DOTALL):
    start_line = content[:m.start()].count('\n') + 1
    scripts.append((start_line, m.group(1)))

print(f"Found {len(scripts)} script blocks\n")

# Check brace balance in each script
for i, (start_line, script) in enumerate(scripts):
    opens = script.count('{')
    closes = script.count('}')
    if opens != closes:
        print(f"Script block starting at line {start_line}:")
        print(f"  {{ count: {opens}")
        print(f"  }} count: {closes}")
        print(f"  IMBALANCE: {opens - closes}")
        
        # Find the approximate location
        balance = 0
        for j, ch in enumerate(script):
            if ch == '{': balance += 1
            elif ch == '}': 
                balance -= 1
                if balance < 0:
                    line_in_script = script[:j].count('\n') + 1
                    abs_line = start_line + line_in_script
                    print(f"  First negative balance at script line {line_in_script} (absolute ~{abs_line})")
                    print(f"  Context: {repr(script[max(0,j-50):j+50])}")
                    break
        print()

# Also check for stray/broken characters
print("\nChecking for encoding issues (question mark replacements)...")
broken = []
for i, line in enumerate(lines, 1):
    if '\ufffd' in line or '?' in line:
        # Only flag lines that are code (not HTML content)
        if '<' not in line and ('function' in line or 'var ' in line or 'const ' in line or 'let ' in line):
            broken.append((i, line.strip()[:100]))

if broken:
    print(f"Found {len(broken)} lines with possible encoding issues:")
    for ln, txt in broken[:10]:
        print(f"  Line {ln}: {txt}")
else:
    print("No obvious encoding issues in code lines.")

print("\nDone.")
