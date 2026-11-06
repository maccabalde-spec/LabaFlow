"""
Generate LabaFlow PNG icons for:
  - Android launcher icons (all densities)
  - Web favicon (16x16, 32x32, 192x192, 512x512)

Uses only stdlib — no Pillow needed.
The LF logo: blue circle + white "LF" text + wave shapes.
We encode everything as raw PNG bytes.
"""

import struct, zlib, math, os

# ── Minimal PNG writer ───────────────────────────────────────

def _chunk(tag: bytes, data: bytes) -> bytes:
    c = tag + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)

def make_png(pixels, size):
    """pixels: list of (r,g,b,a) tuples, row-major"""
    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = _chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))  # RGBA
    raw = b''
    for y in range(size):
        raw += b'\x00'  # filter byte
        for x in range(size):
            r, g, b, a = pixels[y * size + x]
            raw += bytes([r, g, b, a])
    idat = _chunk(b'IDAT', zlib.compress(raw, 9))
    iend = _chunk(b'IEND', b'')
    return sig + ihdr + idat + iend

# ── Rasterizer helpers ───────────────────────────────────────

def lerp(a, b, t):
    return a + (b - a) * t

def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)

def aa_circle(px, py, cx, cy, r, feather=1.0):
    """Returns 0-1 alpha for anti-aliased circle"""
    d = dist(px, py, cx, cy)
    return max(0.0, min(1.0, (r - d + feather) / (2 * feather)))

def blend(bg, fg, alpha):
    """Alpha blend fg onto bg"""
    a = alpha * fg[3] / 255
    r = int(bg[0] * (1-a) + fg[0] * a)
    g = int(bg[1] * (1-a) + fg[1] * a)
    b = int(bg[2] * (1-a) + fg[2] * a)
    aa = min(255, int(bg[3] + fg[3] * a))
    return (r, g, b, aa)

# ── Draw a character using a simple bitmap font ──────────────
# Each char is 5×7 bitmap

FONT = {
    'L': [
        0b10000,
        0b10000,
        0b10000,
        0b10000,
        0b10000,
        0b10000,
        0b11111,
    ],
    'F': [
        0b11111,
        0b10000,
        0b10000,
        0b11110,
        0b10000,
        0b10000,
        0b10000,
    ],
}

def draw_text_LF(pixels, size, x_offset, y_offset, char_w, char_h, gap, color):
    """Draw 'LF' text onto pixels array"""
    chars = ['L', 'F']
    for ci, ch in enumerate(chars):
        bmap = FONT[ch]
        cx_start = x_offset + ci * (char_w + gap)
        for row_i, row_bits in enumerate(bmap):
            py = y_offset + int(row_i * char_h / 7)
            py_end = y_offset + int((row_i + 1) * char_h / 7)
            for col_i in range(5):
                bit = (row_bits >> (4 - col_i)) & 1
                if bit:
                    px_start = cx_start + int(col_i * char_w / 5)
                    px_end   = cx_start + int((col_i + 1) * char_w / 5)
                    for ry in range(py, py_end):
                        for rx in range(px_start, px_end):
                            if 0 <= rx < size and 0 <= ry < size:
                                idx = ry * size + rx
                                pixels[idx] = blend(pixels[idx], color, 1.0)

# ── Main renderer ─────────────────────────────────────────────

def render_logo(size):
    pixels = [(0, 0, 0, 0)] * (size * size)
    cx = cy = size / 2
    r_outer = size / 2 - 1

    # Colors
    BG_DARK  = (3,  105, 161, 255)   # #0369a1
    BG_MED   = (2,  132, 199, 255)   # #0284c7
    WAVE1    = (56, 189, 248, 180)   # #38bdf8 semi
    WAVE2    = (125,211, 252, 140)   # #7dd3fc semi
    WHITE    = (255,255,255, 255)
    BUBBLE1  = (255,255,255,  64)
    BUBBLE2  = (255,255,255,  51)

    feather = max(1.0, size * 0.004)

    for y in range(size):
        for x in range(size):
            idx = y * size + x
            nx  = x / size  # normalized 0-1
            ny  = y / size

            # 1. Outer circle mask
            a_outer = aa_circle(x, y, cx, cy, r_outer, feather)
            if a_outer <= 0:
                continue

            # 2. Background gradient (dark center → medium)
            d_frac = dist(x, y, cx, cy) / r_outer
            bg_r = int(lerp(BG_DARK[0], BG_MED[0], d_frac))
            bg_g = int(lerp(BG_DARK[1], BG_MED[1], d_frac))
            bg_b = int(lerp(BG_DARK[2], BG_MED[2], d_frac))
            pixels[idx] = (bg_r, bg_g, bg_b, int(255 * a_outer))

            # 3. Wave 1 — sine wave shape bottom area
            wave_y1 = cy + size * 0.08
            wave_amp = size * 0.06
            wave_freq = 2.5
            wave_off1 = wave_y1 + math.sin(nx * math.pi * 2 * wave_freq) * wave_amp
            if y > wave_off1 and y < wave_off1 + size * 0.18:
                alpha1 = min(1.0, (y - wave_off1) / (size * 0.05)) * (WAVE1[3] / 255)
                pixels[idx] = blend(pixels[idx], WAVE1, alpha1)

            # 4. Wave 2 — lower wave
            wave_off2 = wave_y1 + size * 0.12 + math.sin(nx * math.pi * 2 * wave_freq + 0.8) * wave_amp
            if y > wave_off2 and y < wave_off2 + size * 0.20:
                alpha2 = min(1.0, (y - wave_off2) / (size * 0.05)) * (WAVE2[3] / 255)
                pixels[idx] = blend(pixels[idx], WAVE2, alpha2)

    # 5. Bubble decorations
    bubbles = [
        (0.29, 0.31, 0.039, BUBBLE1),
        (0.39, 0.24, 0.024, BUBBLE2),
        (0.66, 0.29, 0.031, BUBBLE2),
        (0.76, 0.37, 0.020, BUBBLE1),
        (0.72, 0.24, 0.043, BUBBLE2),
    ]
    for bx, by, br, bc in bubbles:
        bcx = bx * size; bcy = by * size; brr = br * size
        for y in range(max(0, int(bcy-brr-2)), min(size, int(bcy+brr+2))):
            for x in range(max(0, int(bcx-brr-2)), min(size, int(bcx+brr+2))):
                idx = y * size + x
                if pixels[idx][3] == 0: continue
                ba = aa_circle(x, y, bcx, bcy, brr, feather)
                if ba > 0:
                    pixels[idx] = blend(pixels[idx], bc, ba)

    # 6. Draw 'LF' text
    text_h  = int(size * 0.42)
    text_w  = int(size * 0.22)
    gap     = int(size * 0.04)
    total_w = text_w * 2 + gap
    tx = (size - total_w) // 2
    ty = int(size * 0.25)
    draw_text_LF(pixels, size, tx, ty, text_w, text_h, gap, WHITE)

    return pixels

# ── Generate all sizes ────────────────────────────────────────

def save_icon(path, size):
    pixels = render_logo(size)
    data   = make_png(pixels, size)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data)
    print(f'  ✓  {path}  ({size}x{size})')

base = r'c:\Users\chrst\Desktop\LabaFlow'

print('\n=== Generating LabaFlow icons ===\n')

# Android launcher icons
android_sizes = {
    r'flutter_mobile\android\app\src\main\res\mipmap-mdpi\ic_launcher.png':    48,
    r'flutter_mobile\android\app\src\main\res\mipmap-hdpi\ic_launcher.png':    72,
    r'flutter_mobile\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png':   96,
    r'flutter_mobile\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png':  144,
    r'flutter_mobile\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png': 192,
}
print('Android launcher icons:')
for rel, sz in android_sizes.items():
    save_icon(os.path.join(base, rel), sz)

# Web / PWA icons
web_sizes = {
    r'public\favicon-16.png':  16,
    r'public\favicon-32.png':  32,
    r'public\icon-192.png':   192,
    r'public\icon-512.png':   512,
}
print('\nWeb / PWA icons:')
for rel, sz in web_sizes.items():
    save_icon(os.path.join(base, rel), sz)

print('\n=== All icons generated! ===\n')
