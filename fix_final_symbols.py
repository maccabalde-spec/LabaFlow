path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

fixes = [
    # Call mute toggle — was set to wrong emoji by catch-all
    ("if(btn)btn.textContent=_callMuted?'🧺':'🧺';",
     "if(btn)btn.textContent=_callMuted?'🔇':'🎤';"),

    # Theme button update function — was set to wrong emoji
    ("b.textContent=isLightApp?'🧺':'🧺';",
     "b.textContent=isLightApp?'☀️':'🌙';"),

    # Default notification icon
    ("icon=icon||'🧺';",
     "icon=icon||'🔔';"),

    # RELEASED order icon — was set to 🧺 by catch-all, should be 🎉
    ("RELEASED:{icon:'🧺',title:`Order",
     "RELEASED:{icon:'🎉',title:`Order"),

    # Seller bell when empty (no notifications)
    ("`:'🧺';",
     "`:'🔔';"),
]

count = 0
for old, new in fixes:
    c = content.count(old)
    if c > 0:
        content = content.replace(old, new)
        count += c
        print(f"  ✓ Fixed {c}x: {repr(old[:70])}")
    else:
        print(f"  ✗ NOT FOUND: {repr(old[:70])}")

# Also fix any remaining ?? in JS (the catch-all missed some due to encoding)
import re

# Scan for literal ?? in JS that are still broken
broken = list(re.finditer(r'\?\?', content))
if broken:
    print(f"\nFound {len(broken)} remaining ?? instances — showing context:")
    for m in broken[:10]:
        ctx = content[max(0,m.start()-30):m.start()+50]
        print(f"  pos {m.start()}: {repr(ctx)}")

print(f"\nTotal: {count} fixes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
