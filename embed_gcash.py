import re

# Instead of embedding base64, just reference the image file directly
# The QR image will be served as a separate file alongside the HTML

files = [
    'C:/LabaFlow/flutter_mobile/assets/labaflow.html',
    'C:/LabaFlow/flutter_mobile/web/labaflow.html',
]

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
    '  img.onerror=function(){el.innerHTML="<div style=\'padding:10px;font-size:13px;color:#333;text-align:center;\'>GCash: "+fmt+"</div>";};\n'
    '  el.appendChild(img);\n'
    '}'
)

for path in files:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            html = f.read()

        # Remove any old base64 constant
        html = re.sub(r"const GCASH_QR_B64='[^']*';\n?", '', html)

        # Replace renderGcashQR function
        old_start = 'function renderGcashQR(){'
        idx = html.find(old_start)
        if idx == -1:
            print('Not found in: ' + path)
            continue

        depth = 0
        end_idx = idx
        for i, ch in enumerate(html[idx:], start=idx):
            if ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    end_idx = i + 1
                    break

        html = html[:idx] + new_func + html[end_idx:]

        with open(path, 'w', encoding='utf-8') as f:
            f.write(html)

        print('Updated: ' + path)
    except Exception as e:
        print('Error: ' + str(e))

print('DONE')
