import re

path = 'C:/LabaFlow/flutter_mobile/assets/labaflow.html'

with open(path, 'r', encoding='utf-8') as f:
    html = f.read()

# Remove bundled sweetalert2
html = re.sub(
    r'<script>var SweetAlert2.*?</script>',
    '<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>',
    html, flags=re.DOTALL
)

# Remove bundled chart.js
html = re.sub(
    r'<script>!function\(t,e\).*?</script>',
    '<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>',
    html, flags=re.DOTALL
)

# Remove bundled qrcodejs
html = re.sub(
    r'<script>var QRCode.*?</script>',
    '<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>',
    html, flags=re.DOTALL
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(html)

import os
size = os.path.getsize(path)
print(f'Done! New size: {size} bytes = {size/1024:.1f} KB')
