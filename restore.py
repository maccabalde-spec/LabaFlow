import os, re, base64

# Read the ORIGINAL clean LabaFlow.html from OneDrive
src = 'C:/Users/chrst/OneDrive/Desktop/LabaFlow/LabaFlow.html'
dst = 'C:/LabaFlow/flutter_mobile/assets/labaflow.html'

with open(src, 'r', encoding='utf-8') as f:
    html = f.read()

print(f'Original clean HTML size: {len(html)/1024:.1f} KB')

# Add GCash QR fix - replace renderGcashQR with file reference version
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
    print('GCash QR function updated')

with open(dst, 'w', encoding='utf-8') as f:
    f.write(html)

final_size = os.path.getsize(dst)
print(f'Final size: {final_size/1024:.1f} KB')
print('DONE')
