"""
Emergency restore: remove ALL the injected CSS blocks that broke the landing page.
Keep only the essential original CSS + one clean dashboard theme addition.
"""
path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

print(f"File size before: {len(content)}")

# Remove every injected block (marked by ════ border)
while True:
    idx = content.find('/* ════')
    if idx == -1:
        break
    # Find the end of this comment block
    end = content.find('\n\n\n', idx)
    if end == -1 or end - idx > 15000:
        end = idx + 200  # safety
    removed = content[idx:end+3]
    content = content[:idx] + content[end+3:]
    print(f"  Removed block at {idx} ({len(removed)} chars): {removed[:60]!r}")

# Also remove individual injected CSS that breaks things
broken_pieces = [
    # The Nunito font import that may fail
    "@import url('https://fonts.googleapis.com/css2?family=Nunito",
    # body inline style that overrides
    '<body style="background:#f0f9ff;">',
    # duplicate body rules
    '\nbody { background: #f0f9ff; }\n#landing { background: transparent; }',
    '\n/* Body defaults to landing page sky blue background */\nbody { background: #f0f9ff; }',
    '\nbody { background: #f0f9ff; }',
    # Landing background transparent (wrong)
    '\n#landing { background: transparent; }',
    '/* Landing page sections have their own backgrounds */\n#landing { background: transparent; }',
    '/* background set via body style attribute */',
]

for piece in broken_pieces:
    if piece in content:
        content = content.replace(piece, '')
        print(f"  Removed: {piece[:60]!r}")

# Fix body tag back to normal
content = content.replace('<body style="background:#f0f9ff;">', '<body>', 1)
content = content.replace('<body style="background: #f0f9ff;">', '<body>', 1)

# Now add ONE simple addition at the very end of the main <style> block:
# Just the dashboard sky blue theme, nothing that affects landing

CLEAN_ADDITION = """

/* ── Dashboard Sky Blue Theme ── */
body:not(.lf-light) .content{background:radial-gradient(circle at 15% 20%,rgba(56,189,248,.07) 80px,transparent 80px),radial-gradient(circle at 85% 80%,rgba(14,165,233,.06) 100px,transparent 100px),#071525!important;}
body:not(.lf-light) .pt-wrap{background:#071525!important;}
body:not(.lf-light) .sidebar{background:linear-gradient(180deg,#040d18,#071525)!important;border-right:1px solid rgba(56,189,248,.12)!important;}
body:not(.lf-light) .topbar{background:rgba(4,13,24,.97)!important;border-bottom:1px solid rgba(56,189,248,.15)!important;}
body:not(.lf-light) .tb-title{color:#38bdf8!important;font-weight:800!important;}
.nav-item.active{background:rgba(56,189,248,.12)!important;border-left:3px solid #38bdf8!important;color:#38bdf8!important;}
.nav-item:hover{background:rgba(56,189,248,.07)!important;color:#90c4e4!important;}
body:not(.lf-light) .sc{background:linear-gradient(135deg,#0c2040,#091830)!important;border:1px solid rgba(56,189,248,.15)!important;border-radius:14px!important;}
body:not(.lf-light) .sc:hover{border-color:rgba(56,189,248,.4)!important;box-shadow:0 8px 28px rgba(2,132,199,.2)!important;transform:translateY(-3px)!important;}
body:not(.lf-light) .card{background:linear-gradient(135deg,#0c2040,#091830)!important;border:1px solid rgba(56,189,248,.12)!important;border-radius:14px!important;}
body:not(.lf-light) .ch{background:rgba(56,189,248,.07)!important;border-bottom:1px solid rgba(56,189,248,.12)!important;}
body:not(.lf-light) .ch h4{color:#38bdf8!important;font-weight:800!important;}
body:not(.lf-light) th{background:rgba(56,189,248,.09)!important;color:#7dd3fc!important;}
body:not(.lf-light) td{color:#e0f2fe!important;}
body:not(.lf-light) tbody tr:hover td{background:rgba(56,189,248,.06)!important;}
.btn-primary{background:linear-gradient(135deg,#0ea5e9,#0369a1)!important;border:none!important;border-radius:50px!important;font-weight:700!important;}
body:not(.lf-light) .pt-nav{background:rgba(4,13,24,.97)!important;border-bottom:1px solid rgba(56,189,248,.15)!important;}
body:not(.lf-light) .pt-tab{color:#4a7fa8!important;font-weight:700!important;}
body:not(.lf-light) .pt-tab.active{color:#38bdf8!important;border-bottom-color:#38bdf8!important;}
body:not(.lf-light) .ord-card{background:linear-gradient(135deg,#0c2040,#091830)!important;border:1px solid rgba(56,189,248,.15)!important;border-radius:14px!important;}
.loyalty-card{background:linear-gradient(135deg,#0369a1,#0284c7,#0ea5e9)!important;border-radius:20px!important;}
.msg-mine{background:linear-gradient(135deg,#0284c7,#0369a1)!important;}
.sb-logo span{color:#38bdf8!important;}
body.lf-light .content{background:#f0f9ff!important;}
body.lf-light .pt-wrap{background:#f0f9ff!important;}
body.lf-light .sidebar{background:#fff!important;box-shadow:1px 0 0 #bae6fd!important;}
body.lf-light .topbar{background:#fff!important;border-bottom:1px solid #bae6fd!important;}
body.lf-light .tb-title{color:#0284c7!important;}
body.lf-light .sc{background:#fff!important;border:1.5px solid #bae6fd!important;border-radius:14px!important;}
body.lf-light .card{background:#fff!important;border:1px solid #bae6fd!important;border-radius:14px!important;}
body.lf-light .ch{background:#e0f2fe!important;border-bottom:1px solid #bae6fd!important;}
body.lf-light .ch h4{color:#0284c7!important;}
body.lf-light .nav-item.active{background:rgba(2,132,199,.1)!important;border-left-color:#0284c7!important;color:#0284c7!important;}
"""

# Insert before the FIRST </style> tag (end of main styles)
style_end = content.find('</style>')
if style_end != -1:
    content = content[:style_end] + CLEAN_ADDITION + '\n' + content[style_end:]
    print("✓ Added clean dashboard CSS at end of main styles")

print(f"File size after: {len(content)}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
