path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the Unsplash laundry URL with the local hero-bg.jpg
import re

# Find and replace the background in .lp-hero-wrapper
old_bg = r"""url('https://images.unsplash.com/photo-1567113463300-102a7eb3cb26?w=1600&auto=format&fit=crop&q=80') center/cover no-repeat;"""
new_bg = r"""url('hero-bg.jpg') center bottom/cover no-repeat;"""

if old_bg in content:
    content = content.replace(old_bg, new_bg)
    print("✓ Updated hero background to hero-bg.jpg")
else:
    # Try broader search
    found = re.search(r"url\('[^']*unsplash[^']*'\)\s*center[^;]*;", content)
    if found:
        content = content.replace(found.group(0), "url('hero-bg.jpg') center bottom/cover no-repeat;")
        print("✓ Updated hero background via regex")
    else:
        # Just find any hero wrapper background and update it
        idx = content.find('.lp-hero-wrapper {')
        if idx != -1:
            # Find background: in that block
            block_end = content.find('}', idx)
            block = content[idx:block_end]
            print(f"Hero wrapper block: {repr(block[:200])}")
        print("⚠ Could not find background URL to replace, check manually")

# Also adjust the overlay to work better with the cartoon image
old_overlay = r"""  background:
    linear-gradient(
      135deg,
      rgba(2,98,168,.87) 0%,
      rgba(3,105,161,.80) 40%,
      rgba(14,165,233,.60) 75%,
      rgba(56,189,248,.40) 100%
    ),
    url('hero-bg.jpg') center bottom/cover no-repeat;"""

new_overlay = r"""  background:
    linear-gradient(
      135deg,
      rgba(2,98,168,.82) 0%,
      rgba(3,105,161,.75) 35%,
      rgba(14,165,233,.50) 70%,
      rgba(56,189,248,.25) 100%
    ),
    url('hero-bg.jpg') center bottom/cover no-repeat;"""

if old_overlay in content:
    content = content.replace(old_overlay, new_overlay)
    print("✓ Adjusted overlay opacity to show image better")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
