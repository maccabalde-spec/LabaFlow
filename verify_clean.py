"""
Final verification: check for actual JS syntax errors.
Uses Node.js if available to parse JS.
Otherwise does careful manual check.
"""
import re, subprocess, os

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Extract all script blocks
pattern = re.compile(r'<script(?![^>]*type=["\']module["\'])[^>]*>(.*?)</script>', re.DOTALL)
scripts = list(pattern.finditer(content))
print(f"Found {len(scripts)} non-module script blocks")

# Try node.js syntax check
has_node = subprocess.run(['node', '--version'], capture_output=True).returncode == 0
print(f"Node.js available: {has_node}")

errors_found = False
for i, m in enumerate(scripts):
    start_line = content[:m.start()].count('\n') + 1
    js = m.group(1)
    
    if len(js.strip()) < 10:
        continue
    
    if has_node:
        # Write JS to temp file and check syntax
        tmp = f'c:\\Users\\chrst\\Desktop\\LabaFlow\\tmp_check_{i}.js'
        with open(tmp, 'w', encoding='utf-8') as f:
            f.write(js)
        result = subprocess.run(['node', '--check', tmp], capture_output=True, text=True)
        if result.returncode != 0:
            print(f"\n✗ SYNTAX ERROR in block at line {start_line}:")
            # Adjust line numbers
            err = result.stderr.replace(tmp, f'line {start_line}+')
            print(f"  {err.strip()[:200]}")
            errors_found = True
        else:
            print(f"  ✓ Block at line {start_line} ({len(js)} chars) - OK")
        os.remove(tmp)
    else:
        # Manual check: count ₱ that look like operators
        peso_ops = []
        for pat in [r"===\s*'[^']*'\s*₱", r"\)\s*₱\s*'", r"[a-zA-Z]\s*₱\s*'"]:
            for m2 in re.finditer(pat, js):
                line_no = start_line + js[:m2.start()].count('\n')
                ctx = js[max(0,m2.start()-10):m2.start()+30]
                peso_ops.append((line_no, ctx))
        if peso_ops:
            print(f"\n✗ Possible ₱ operators in block at line {start_line}:")
            for ln, ctx in peso_ops[:3]:
                print(f"  Line {ln}: {repr(ctx)}")
            errors_found = True
        else:
            print(f"  ✓ Block at line {start_line} - No ₱ operator issues")

if not errors_found:
    print("\n✅ All script blocks look clean!")
else:
    print("\n⚠️ Some issues found — check above")

print("\nDone.")
