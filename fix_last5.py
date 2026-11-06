path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the 5 remaining ?? instances by position context
fixes = [
    # Theme button in app shell (admin/seller topbar - the remaining one)
    ('onclick="toggleTheme()">??</button>\n\n      <button class="btn btn-ghost bt',
     'onclick="toggleTheme()">🌙</button>\n\n      <button class="btn btn-ghost bt'),

    # GCash settings section labels
    ('<span style="font-size:18px;">??</span> GCash Number',
     '<span style="font-size:18px;">📱</span> GCash Number'),
    ('<span style="font-size:18px;">??</span> GCash QR Code Image',
     '<span style="font-size:18px;">🖼️</span> GCash QR Code Image'),
    ('<span style="font-size:20px;">??</span> Click to upload QR image',
     '<span style="font-size:20px;">📤</span> Click to upload QR image'),

    # GCash use default button
    ('onclick="removeGcashQR()">??Use Default</button>',
     'onclick="removeGcashQR()">↩ Use Default</button>'),
]

count = 0
for old, new in fixes:
    c = content.count(old)
    if c > 0:
        content = content.replace(old, new)
        count += c
        print(f"  ✓ {repr(old[:60])}")

print(f"\nFixed: {count}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
