import base64

# Read the real GCash QR image
with open('D:/Download/gcash_qr.png', 'rb') as f:
    data = f.read()

# Detect if it's actually JPEG
is_jpeg = data[:2] == b'\xff\xd8'
mime = 'image/jpeg' if is_jpeg else 'image/png'
b64 = 'data:' + mime + ';base64,' + base64.b64encode(data).decode()

print('Image type:', mime)
print('Base64 length:', len(b64))

# Update assets/labaflow.html - replace the img.src line
path = 'C:/LabaFlow/flutter_mobile/assets/labaflow.html'
with open(path, 'r', encoding='utf-8') as f:
    html = f.read()

old = 'img.src="gcash_qr.png";'
new = 'img.src="' + b64 + '";'

if old in html:
    html = html.replace(old, new)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(html)
    print('SUCCESS: Updated assets/labaflow.html')
else:
    print('ERROR: Could not find img.src="gcash_qr.png" in HTML')
    # Show what IS there
    idx = html.find('renderGcashQR')
    print('Found near renderGcashQR:', repr(html[idx:idx+400]))
