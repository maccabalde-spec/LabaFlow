import re

dst = 'C:/LabaFlow/flutter_mobile/assets/labaflow.html'

with open(dst, 'r', encoding='utf-8') as f:
    html = f.read()

# Replace the huge base64 back to gcash_qr.png
new_chunk = re.sub(
    r'img\.src="data:[^"]*";',
    'img.src="gcash_qr.png";',
    html
)

with open(dst, 'w', encoding='utf-8') as f:
    f.write(new_chunk)

print('DONE - removed base64, restored gcash_qr.png reference')
