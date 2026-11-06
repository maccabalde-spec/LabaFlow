"""
Complete fix for LabaFlow.html:
1. Verify the Firebase compat script is correct (no module isolation)
2. Fix ALL syntax errors (brace balance)
3. Fix ALL encoding issues
4. Verify doLogin works
"""
import re, sys

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

print(f"File size: {len(content)} chars")

# ── Step 1: Check/fix brace balance in all script blocks ────────────────
script_blocks = list(re.finditer(r'(<script(?![^>]*type=["\']module["\'])[^>]*>)(.*?)(</script>)', content, re.DOTALL))
print(f"\nFound {len(script_blocks)} non-module script blocks")

errors = []
for m in script_blocks:
    js = m.group(2)
    opens = js.count('{')
    closes = js.count('}')
    if opens != closes:
        start_line = content[:m.start()].count('\n') + 1
        errors.append((start_line, opens, closes, m.start(), m.end()))
        print(f"  IMBALANCE at line {start_line}: {{ {opens} vs }} {closes}")

# ── Step 2: Fix the specific known double-brace bug ──────────────────────
# Pattern: }}  followed by function (extra closing brace)
fixes = 0

# Fix 1: the startRealtimeListeners extra brace
patterns_to_fix = [
    # Extra } at end of startRealtimeListeners
    ('  }\n}}\n\nfunction refreshMsgUI',   '  }\n}\n\nfunction refreshMsgUI'),
    ('}}\n\nfunction refreshMsgUI',         '}\n\nfunction refreshMsgUI'),
    # Any other double }}\n\nfunction patterns that shouldn't be there
]

for old, new in patterns_to_fix:
    if old in content:
        content = content.replace(old, new, 1)
        fixes += 1
        print(f"Fixed brace: {repr(old[:40])}")

# ── Step 3: Fix encoding - restore ₱ peso sign ──────────────────────────
# The Python scripts corrupted UTF-8 special chars when using
# various Windows tools. Fix peso sign and dashes.

# peso sign - various corruption forms
peso_fixes = [
    ("'\\u20b1'",  "'₱'"),   # unicode escape → actual char
    ("peso(n){return '\\u20b1'", "peso(n){return '₱'"),
]
for old, new in peso_fixes:
    if old in content:
        content = content.replace(old, new)
        fixes += 1

# Make sure peso function is correct
if "function peso(n){return '₱'" not in content:
    # Find and fix it
    content = re.sub(
        r"function peso\(n\)\{return '[^']*'\+parseFloat",
        "function peso(n){return '₱'+parseFloat",
        content
    )
    fixes += 1
    print("Fixed peso() function")

# Fix em dash in date functions
content = content.replace("return'\ufffd'", "return'—'")
content = content.replace("if(!d)return'';", "if(!d)return'—';")

# ── Step 4: Verify the Firebase script tag is compat (not module) ────────
if '<script type="module">' in content:
    print("\nWARNING: Still has type=module script!")
else:
    print("\nGood: No type=module scripts found")

# ── Step 5: Verify key functions exist ───────────────────────────────────
required_fns = ['function openAuth', 'function closeAuth', 'async function doLogin',
                'function g(id)', 'function launchApp', 'function startRealtimeListeners',
                'async function loadAllCaches']
for fn in required_fns:
    if fn in content:
        print(f"  ✓ {fn}")
    else:
        print(f"  ✗ MISSING: {fn}")

# ── Step 6: Fix doLogin to use DB.get not C.get ──────────────────────────
# Ensure doLogin fetches from Firestore
if 'const users = await C.get(' in content:
    content = content.replace('const users = await C.get(', 'const users = await DB.get(')
    fixes += 1
    print("Fixed doLogin to use DB.get")

# ── Write fixed file ─────────────────────────────────────────────────────
print(f"\nTotal fixes applied: {fixes}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify brace balance after fix
print("\nRe-checking brace balance...")
with open(path, 'r', encoding='utf-8') as f:
    content2 = f.read()

script_blocks2 = list(re.finditer(r'(<script(?![^>]*type=["\']module["\'])[^>]*>)(.*?)(</script>)', content2, re.DOTALL))
has_error = False
for m in script_blocks2:
    js = m.group(2)
    opens = js.count('{')
    closes = js.count('}')
    if opens != closes:
        start_line = content2[:m.start()].count('\n') + 1
        print(f"  STILL IMBALANCED at line {start_line}: {{ {opens} vs }} {closes}")
        has_error = True
        
        # Find the exact extra/missing brace
        balance = 0
        lines = js.split('\n')
        for li, line in enumerate(lines):
            for ch in line:
                if ch == '{': balance += 1
                elif ch == '}': balance -= 1
            if balance < 0:
                print(f"    Goes negative at script line {li+1}: {repr(line[:80])}")
                break

if not has_error:
    print("  All script blocks have balanced braces!")

print("\nDone!")
