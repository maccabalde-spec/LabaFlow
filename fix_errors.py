path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

original_len = len(content)

# ── Fix 1: Extra closing brace in startRealtimeListeners ────────────────
# The bug: '}\n}}\n\nfunction' — double }} should be single }
import re

# Find the exact problematic pattern
bad = '  }\n}}\n\nfunction refreshMsgUI'
good = '  }\n}\n\nfunction refreshMsgUI'

if bad in content:
    content = content.replace(bad, good, 1)
    print("Fixed: extra } in startRealtimeListeners")
else:
    # Try alternative patterns
    bad2 = '}}\n\nfunction refreshMsgUI'
    good2 = '}\n\nfunction refreshMsgUI'
    if bad2 in content:
        content = content.replace(bad2, good2, 1)
        print("Fixed: extra }} before refreshMsgUI")
    else:
        print("WARNING: Could not find double-brace pattern")
        # Show context around refreshMsgUI
        idx = content.find('function refreshMsgUI')
        print(f"Context before: {repr(content[idx-30:idx])}")

# ── Fix 2: Restore encoding issues ──────────────────────────────────────
# The Python scripts were writing with UTF-8 but Windows cmd was
# corrupting certain chars. Fix known corruptions:

replacements = [
    # Peso sign corruptions
    ("'?'+",        "'₱'+"),
    ("'?'",         "'₱'"),
    ("`?",          "`₱"),
    ("? ",          "₱"),   # be careful - only in known contexts
    
    # Corrupted helper function returns  
    ("return'?';",  "return'—';"),
    ("return'';",   "return'—';"),
    
    # Specific known broken strings
    ("`?180 base (7kg)`",  "`₱180 base (7kg)`"),
    ("`?190 base (5kg)`",  "`₱190 base (5kg)`"),
    ("'?'+parseFloat",     "'₱'+parseFloat"),
    ("return '?'+",        "return '₱'+"),
]

fixed_count = 0
for old, new in replacements:
    count = content.count(old)
    if count > 0:
        content = content.replace(old, new)
        fixed_count += count
        print(f"Fixed {count}x: {repr(old)} -> {repr(new)}")

# Fix peso function specifically
content = content.replace(
    "function peso(n){return '?'+parseFloat(n||0).toFixed(2);}",
    "function peso(n){return '\u20b1'+parseFloat(n||0).toFixed(2);}"
)

# Fix fd/fs functions that show corrupted date fallback
content = content.replace("return'\ufffd'", "return'\u2014'")
content = content.replace("return''", "return'\u2014'")  # only in date functions

print(f"\nTotal: {fixed_count} encoding fixes applied")
print(f"File size: {original_len} -> {len(content)} chars")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\nDone!")
