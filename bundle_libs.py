import urllib.request, os

src = 'C:/Users/chrst/OneDrive/Desktop/LabaFlow/LabaFlow.html'
dst = 'C:/LabaFlow/flutter_mobile/assets/labaflow.html'

libs = [
    (
        '<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>',
        'https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js'
    ),
    (
        '<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>',
        'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js'
    ),
    (
        '<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>',
        'https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js'
    ),
]

# Read original clean HTML
with open(src, 'r', encoding='utf-8') as f:
    html = f.read()

print(f'Source size: {len(html)/1024:.1f} KB')

# Download and bundle each library
for tag, url in libs:
    if tag not in html:
        print(f'SKIP (not found): {url}')
        continue
    print(f'Downloading: {url}')
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        content = r.read().decode('utf-8', errors='replace')
    html = html.replace(tag, f'<script>{content}</script>')
    print(f'  Bundled: {len(content)/1024:.1f} KB')

# Fix GCash QR function
import re
old_func_start = 'function renderGcashQR(){'
idx = html.find(old_func_start)
if idx != -1:
    depth = 0
    end_idx = idx
    for i, ch in enumerate(html[idx:], start=idx):
        if ch == '{': depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                end_idx = i + 1
                break
    new_func = (
        'function renderGcashQR(){\n'
        '  const num=getGcashNumber();\n'
        '  const fmt=num.replace(/(\\d{4})(\\d{3})(\\d{4})/,"$1 $2 $3");\n'
        '  const dispEl=g("gcashNumDisplay");\n'
        '  if(dispEl)dispEl.textContent=fmt;\n'
        '  const el=g("gcashQrPattern");\n'
        '  if(!el)return;\n'
        '  el.innerHTML="";\n'
        '  const img=document.createElement("img");\n'
        '  img.src="gcash_qr.png";\n'
        '  img.style.cssText="width:180px;height:180px;display:block;margin:0 auto;border-radius:8px;";\n'
        '  img.alt="GCash QR Code";\n'
        '  el.appendChild(img);\n'
        '}'
    )
    html = html[:idx] + new_func + html[end_idx:]

with open(dst, 'w', encoding='utf-8') as f:
    f.write(html)

final = os.path.getsize(dst)
print(f'\nFinal bundled size: {final/1024:.1f} KB')
print('DONE - app now loads offline and fast!')
