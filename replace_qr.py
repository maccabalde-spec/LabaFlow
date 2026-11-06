import base64
import re
import shutil
import os

# Step 1: Read gcash_qr.png and convert to base64 data URL
with open(r'D:\Download\gcash_qr.png', 'rb') as f:
    raw = f.read()

b64 = base64.b64encode(raw).decode('ascii')
new_data_url = 'data:image/png;base64,' + b64
print(f'[1] PNG read OK. Base64 length: {len(b64)}')
print(f'[1] Data URL prefix (first 50): {new_data_url[:50]}')
print(f'[1] Is JPEG (/9j/)? {b64.startswith("/9j/")}')

# Step 2: Read LabaFlow.html as bytes
html_path = r'C:\Users\chrst\OneDrive\Desktop\LabaFlow\LabaFlow.html'
with open(html_path, 'rb') as f:
    content = f.read()

print(f'[2] HTML file size (before): {len(content)} bytes')

# Find the existing DEFAULT_GCASH_QR line using regex on the decoded text
text = content.decode('utf-8')

pattern = r"(const DEFAULT_GCASH_QR=')[^']*(';" + r")"
match = re.search(pattern, text)
if not match:
    print('[2] ERROR: Could not find DEFAULT_GCASH_QR line!')
else:
    old_full = match.group(0)
    old_value_preview = match.group(0)[len("const DEFAULT_GCASH_QR='"):][:80]
    print(f'[2] Found existing line. Old value prefix: {old_value_preview}')

    new_full = "const DEFAULT_GCASH_QR='" + new_data_url + "';"
    new_text = text.replace(old_full, new_full, 1)

    if new_text == text:
        print('[2] ERROR: Replacement did not change the file!')
    else:
        print('[2] Replacement done successfully.')

    # Step 3: Write the file back
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print(f'[3] File written back to {html_path}')

    # Step 4: Copy to flutter_mobile/assets/
    dest_path = r'C:\Users\chrst\OneDrive\Desktop\LabaFlow\flutter_mobile\assets\labaflow.html'
    shutil.copy2(html_path, dest_path)
    print(f'[4] Copied to {dest_path}')

    # Step 5: Verify
    with open(html_path, 'rb') as f:
        verify_content = f.read()
    verify_text = verify_content.decode('utf-8')

    verify_match = re.search(r"const DEFAULT_GCASH_QR='([^']*)'", verify_text)
    if verify_match:
        val = verify_match.group(1)
        print(f'\n[5] VERIFICATION:')
        print(f'    First 80 chars of new value: {val[:80]}')
        print(f'    Total length of base64 string: {len(val)}')
        print(f'    File size of LabaFlow.html: {os.path.getsize(html_path)} bytes')
        print(f'    Starts with data:image/png;base64,? {val.startswith("data:image/png;base64,")}')
        b64_part = val[len("data:image/png;base64,"):]
        print(f'    Does NOT start with /9j/ (JPEG)? {not b64_part.startswith("/9j/")}')
    else:
        print('[5] ERROR: Could not find DEFAULT_GCASH_QR after writing!')
