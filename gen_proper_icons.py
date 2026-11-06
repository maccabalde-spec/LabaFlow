"""
Generate proper LabaFlow icons that match the mobile app design:
- Blue gradient circle background (#0284c7 to #0369a1)
- White "LF" text centered
- Soap bubble accent
- All required sizes for web and Android
"""
import struct, zlib, math, os

# ── PNG encoder ───────────────────────────────────────────────────────────
def chunk(tag, data):
    c = tag + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)

def make_png(pixels, size):
    sig  = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
    raw  = b''
    for y in range(size):
        raw += b'\x00'
        for x in range(size):
            r, g, b, a = pixels[y * size + x]
            raw += bytes([r, g, b, a])
    idat = chunk(b'IDAT', zlib.compress(raw, 9))
    iend = chunk(b'IEND', b'')
    return sig + ihdr + idat + iend

# ── Pixel helpers ─────────────────────────────────────────────────────────
def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)

def aa_circle(px, py, cx, cy, r, feather=1.5):
    d = dist(px, py, cx, cy)
    return max(0.0, min(1.0, (r - d + feather) / (2 * feather)))

def blend(bg, fg, alpha):
    a = min(1.0, max(0.0, alpha * fg[3] / 255))
    r = int(bg[0] * (1-a) + fg[0] * a)
    g = int(bg[1] * (1-a) + fg[1] * a)
    b = int(bg[2] * (1-a) + fg[2] * a)
    aa = min(255, int(bg[3] * (1-a) + fg[3] * a)) if bg[3] > 0 else int(255 * a)
    return (r, g, b, aa)

# ── Bitmap font for L and F (5×7) ─────────────────────────────────────────
FONT = {
    'L': [0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11110, 0b11110],
    'F': [0b11110, 0b11110, 0b10000, 0b11100, 0b11100, 0b10000, 0b10000],
}

def draw_rect(pixels, size, x1, y1, x2, y2, color, feather=0.8):
    for y in range(max(0, y1-2), min(size, y2+2)):
        for x in range(max(0, x1-2), min(size, x2+2)):
            # Edge softening
            ax = max(0.0, min(1.0, (x - x1 + feather) / feather,
                                   (x2 - x + feather) / feather))
            ay = max(0.0, min(1.0, (y - y1 + feather) / feather,
                                   (y2 - y + feather) / feather))
            a  = ax * ay
            if a > 0:
                pixels[y * size + x] = blend(pixels[y * size + x], color, a)

def draw_LF(pixels, size, ox, oy, char_w, char_h, gap):
    """Draw LF text using bitmap font scaled to char_w × char_h"""
    WHITE = (255, 255, 255, 255)
    for ci, ch in enumerate(['L', 'F']):
        bmap = FONT[ch]
        cx   = ox + ci * (char_w + gap)
        for row, bits in enumerate(bmap):
            row_y1 = oy + round(row * char_h / 7)
            row_y2 = oy + round((row+1) * char_h / 7)
            for col in range(5):
                if (bits >> (4 - col)) & 1:
                    col_x1 = cx + round(col * char_w / 5)
                    col_x2 = cx + round((col+1) * char_w / 5)
                    draw_rect(pixels, size, col_x1, row_y1, col_x2, row_y2, WHITE)

# ── Main renderer ─────────────────────────────────────────────────────────
def render_icon(size):
    pixels = [(0, 0, 0, 0)] * (size * size)
    cx = cy  = size / 2
    r_outer  = size / 2 - 1
    feather  = max(1.0, size * 0.005)

    # Colors
    C1 = (2,  132, 199, 255)   # #0284c7  light blue
    C2 = (3,  105, 161, 255)   # #0369a1  dark blue
    W1 = (56, 189, 248, 100)   # #38bdf8  wave 1
    W2 = (125,211, 252,  70)   # #7dd3fc  wave 2

    for y in range(size):
        for x in range(size):
            idx   = y * size + x
            ao    = aa_circle(x, y, cx, cy, r_outer, feather)
            if ao <= 0: continue

            # Background: gradient from center (dark) to edge (light)
            df   = dist(x, y, cx, cy) / r_outer
            r    = int(C2[0] + (C1[0]-C2[0]) * df)
            g    = int(C2[1] + (C1[1]-C2[1]) * df)
            b    = int(C2[2] + (C1[2]-C2[2]) * df)
            pixels[idx] = (r, g, b, int(255 * ao))

            # Wave 1 — lower third
            nx   = x / size
            wy1  = cy + size * 0.10 + math.sin(nx * math.pi * 5) * size * 0.06
            if wy1 < y < wy1 + size * 0.16:
                fa = min(1.0, (y - wy1) / (size * 0.06)) * (W1[3] / 255)
                pixels[idx] = blend(pixels[idx], W1, fa)

            # Wave 2 — bottom
            wy2  = cy + size * 0.20 + math.sin(nx * math.pi * 5 + 1) * size * 0.06
            if wy2 < y < wy2 + size * 0.18:
                fa = min(1.0, (y - wy2) / (size * 0.06)) * (W2[3] / 255)
                pixels[idx] = blend(pixels[idx], W2, fa)

    # Bubble decorations
    BUBBLE = (255, 255, 255, 55)
    for bx, by, br in [(0.28, 0.30, 0.040), (0.38, 0.23, 0.025), (0.71, 0.28, 0.032)]:
        bcx = bx*size; bcy = by*size; brr = br*size
        for y in range(max(0,int(bcy-brr-2)), min(size, int(bcy+brr+2))):
            for x in range(max(0,int(bcx-brr-2)), min(size, int(bcx+brr+2))):
                idx = y*size+x
                if pixels[idx][3] == 0: continue
                ba  = aa_circle(x, y, bcx, bcy, brr, feather)
                if ba > 0:
                    pixels[idx] = blend(pixels[idx], BUBBLE, ba)

    # LF text — centered, ~45% of icon height
    text_h  = int(size * 0.44)
    text_w  = int(size * 0.23)
    gap     = int(size * 0.05)
    total_w = text_w * 2 + gap
    ox      = (size - total_w) // 2
    oy      = int(size * 0.24)
    draw_LF(pixels, size, ox, oy, text_w, text_h, gap)

    return pixels

def save(path, size):
    px   = render_icon(size)
    data = make_png(px, size)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data)
    print(f'  ✓ {path}  ({size}×{size}, {len(data)} bytes)')

base   = r'c:\Users\chrst\Desktop\LabaFlow'
pub    = base + r'\public'
res    = base + r'\flutter_mobile\android\app\src\main\res'

print('\n=== Generating LabaFlow icons ===\n')

# Web / PWA
print('Web icons:')
save(f'{pub}\\favicon-16.png',  16)
save(f'{pub}\\favicon-32.png',  32)
save(f'{pub}\\icon-192.png',   192)
save(f'{pub}\\icon-512.png',   512)

# Android launcher (all densities)
print('\nAndroid launcher icons:')
android = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi':  144,
    'mipmap-xxxhdpi': 192,
}
for folder, sz in android.items():
    save(f'{res}\\{folder}\\ic_launcher.png', sz)

print('\n=== Done! ===')
