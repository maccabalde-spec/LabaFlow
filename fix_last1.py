path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and fix the exact line 2681 - restock modal cost label
# Use regex to find any variant of this line
import re

# Find Cost per Unit label with any broken chars
old = re.search(r'<label>Cost per Unit \([^)]*\)[^<]*for purchase log</label>', content)
if old:
    print(f"Found: {repr(old.group(0))}")
    content = content.replace(old.group(0),
        '<label>Cost per Unit (₱) — for purchase log</label>')
    print("Fixed!")
else:
    print("Not found by regex, trying alternatives...")
    # Try byte-level search
    idx = content.find('Cost per Unit')
    if idx >= 0:
        ctx = content[idx-10:idx+80]
        print(f"Context: {repr(ctx)}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
