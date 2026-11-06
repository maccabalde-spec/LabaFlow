with open(r'D:\Download\gcash_qr.png', 'rb') as f:
    h = f.read(16)
print('File magic bytes (hex):', h.hex())
print('Is PNG?', h[:4] == bytes([0x89, 0x50, 0x4E, 0x47]))
print('Is JPEG?', h[:3] == bytes([0xFF, 0xD8, 0xFF]))
