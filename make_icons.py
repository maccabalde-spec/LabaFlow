from PIL import Image, ImageDraw, ImageFont
import os, math

def make_icon(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r = size // 2
    # Sky blue circular background with gradient
    for y in range(size):
        for x in range(size):
            dx, dy = x - r, y - r
            if dx*dx + dy*dy <= r*r:
                t = y / size
                cr = int(14  + (2  - 14 ) * t)
                cg = int(165 + (132- 165) * t)
                cb = int(233 + (199- 233) * t)
                img.putpixel((x, y), (cr, cg, cb, 255))
    # White 'LF' text centered
    font_size = int(size * 0.40)
    try:
        font = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', font_size)
    except Exception:
        font = ImageFont.load_default()
    text = 'LF'
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (size - tw) // 2 - bbox[0]
    ty = (size - th) // 2 - bbox[1]
    draw.text((tx, ty), text, fill=(255, 255, 255, 255), font=font)
    return img

sizes = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi':  144,
    'mipmap-xxxhdpi': 192,
}
base = r'flutter_mobile/android/app/src/main/res'
for d, s in sizes.items():
    icon = make_icon(s)
    path = os.path.join(base, d, 'ic_launcher.png')
    icon.save(path)
    print(f'Saved {path} ({s}x{s})')
print('Done')
