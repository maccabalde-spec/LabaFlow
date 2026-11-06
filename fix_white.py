path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# ── Fix 1: Landing page background ──────────────────────────────────
# #landing is transparent but body has no bg → shows white
# Fix: set body default background to the landing page color

old_landing_bg = """/* Landing page sections have their own backgrounds */
#landing { background: transparent; }"""

new_landing_bg = """/* Body defaults to landing page sky blue background */
body { background: #f0f9ff; }
#landing { background: transparent; }"""

if old_landing_bg in content:
    content = content.replace(old_landing_bg, new_landing_bg)
    print("✓ Fixed: body has default sky blue background")
else:
    # Find any existing body background rule and update it
    import re
    # Just inject a simple body rule
    idx = content.find('/* Body font */')
    if idx != -1:
        content = content[:idx] + 'body { background: #f0f9ff; }\n' + content[idx:]
        print("✓ Fixed: injected body background")
    else:
        # Add before first </style>
        style_end = content.find('</style>')
        content = content[:style_end] + '\nbody { background: #f0f9ff; }\n' + content[style_end:]
        print("✓ Fixed: body background at top of styles")

# ── Fix 2: Initial body background on page load (before JS runs) ─────
# Set it via inline style on body tag in HTML
old_body_tag = '<body>'
new_body_tag = '<body style="background:#f0f9ff;">'
if old_body_tag in content:
    content = content.replace(old_body_tag, new_body_tag, 1)
    print("✓ Fixed: body inline style background")

# ── Fix 3: The _waitForDB also needs to set initial background ────────
old_init = '''/* Set initial body background based on session state */
(function(){
  const hasSavedUser = !!sessionStorage.getItem('lf3_cu');
  const appTheme = localStorage.getItem('lf_app_theme') || localStorage.getItem('lf_theme');
  if(hasSavedUser){
    document.body.style.background = (appTheme==='light') ? '#f0f9ff' : '#071525';
  } else {
    document.body.style.background = '#f0f9ff';
  }
})();'''

# Remove this duplicate if it exists
if old_init in content:
    content = content.replace(old_init, '/* background set via body style attribute */')
    print("✓ Removed duplicate background init")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
