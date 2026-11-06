import re, os, base64

path = 'C:/LabaFlow/flutter_mobile/assets/labaflow.html'

with open(path, 'r', encoding='utf-8') as f:
    html = f.read()

original_size = len(html)
print(f'Original size: {original_size/1024:.1f} KB')

# Step 1: Remove ALL bundled script blocks and replace with CDN links
# Find the <head> section and replace all large inline scripts with CDN links

# Remove any inline bundled sweetalert (starts with specific patterns)
html = re.sub(r'<script>[^<]{50000,}</script>', '', html, flags=re.DOTALL)
html = re.sub(r'<script>[^<]{10000,}</script>', '', html, flags=re.DOTALL)

# Make sure CDN links are present after head tag
cdn_scripts = '''<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>'''

# Check if CDN links exist, if not add them
if 'sweetalert2@11' not in html:
    html = html.replace('</head>', cdn_scripts + '\n</head>')
    print('Added CDN links')
else:
    print('CDN links already present')

# Step 2: Remove any leftover base64 in gcash QR - replace with placeholder
html = re.sub(
    r'img\.src="data:image/[^"]{1000,}";',
    'img.src="gcash_qr.png";',
    html
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(html)

new_size = os.path.getsize(path)
print(f'New size: {new_size/1024:.1f} KB')
print('DONE')
