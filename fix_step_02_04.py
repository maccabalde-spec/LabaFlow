path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

def replace_old_step(content, step_num_text, icon, title, desc, img_src, img_alt, img_icon):
    """Replace an old-format step card (no image) with a new one with image."""
    # Find the step by its step-num text
    pattern = re.compile(
        r'<div class="lp-step">\s*\n\s*<div class="lp-step-num">' + re.escape(step_num_text) + r'</div>.*?</div>\s*\n\s*</div>',
        re.DOTALL
    )
    new_card = f'''<div class="lp-step">
        <img class="lp-step-img" loading="lazy"
          src="{img_src}"
          alt="{img_alt}"
          onerror="this.style.display='none';this.nextElementSibling.style.display='flex';"
        >
        <div class="lp-step-img-placeholder" style="display:none;">{img_icon}</div>
        <div class="lp-step-body">
          <div class="lp-step-num">{step_num_text.replace("Step ", "")}</div>
          <span class="lp-step-icon">{icon}</span>
          <h4>{title}</h4>
          <p>{desc}</p>
        </div>
      </div>'''
    result, n = pattern.subn(new_card, content)
    return result, n

content, n2 = replace_old_step(
    content,
    'Step 02', '📡',
    'RFID Tag Assigned',
    'Your laundry gets a unique RFID tag. We scan it to receive your items — your order is now tracked in real-time.',
    'rfid.jpg', 'RFID tag scanning laundry', '📡'
)
print(f"Step 02 replacements: {n2}")

content, n4 = replace_old_step(
    content,
    'Step 04', '✅',
    'Ready for Pickup',
    "You'll be notified when your laundry is ready. Pick up and pay — or earn loyalty points with every order!",
    'pick-up.jpg', 'Laundry pickup', '✅'
)
print(f"Step 04 replacements: {n4}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
