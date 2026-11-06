"""
1. Fix hero background to a laundry-themed image (washing machine + bubbles)
2. Apply sky blue theme to all dashboards (app palette update)
"""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ══════════════════════════════════════════════════════════════════════
# FIX 1: Replace hero background with proper laundry images
# Use multiple good laundry images via CSS layering
# ══════════════════════════════════════════════════════════════════════
old_bg = "background: #0284c7 url('https://images.pexels.com/photos/5591663/pexels-photo-5591663.jpeg?auto=compress&cs=tinysrgb&w=1600') center/cover no-repeat;"

new_bg = r"""/* Laundry shop hero — washing machine + soap bubbles sky blue */
  background:
    linear-gradient(
      135deg,
      rgba(2,98,168,.87) 0%,
      rgba(3,105,161,.80) 40%,
      rgba(14,165,233,.60) 75%,
      rgba(56,189,248,.40) 100%
    ),
    url('https://images.unsplash.com/photo-1567113463300-102a7eb3cb26?w=1600&auto=format&fit=crop&q=80') center/cover no-repeat;"""

if old_bg in content:
    content = content.replace(old_bg, new_bg)
    count += 1
    print("✓ Fixed hero background to laundry washing machine image")
else:
    # Try finding it differently
    idx = content.find('.lp-hero-wrapper {')
    if idx != -1:
        # Find the background line within it
        bg_idx = content.find("background: #0284c7", idx)
        if bg_idx == -1:
            bg_idx = content.find("background:", idx)
        print(f"Hero wrapper found at {idx}, bg at {bg_idx}")
        if bg_idx != -1:
            end_bg = content.find(';', bg_idx)
            old_bg_found = content[bg_idx:end_bg+1]
            content = content.replace(old_bg_found,
                r"""background:
    linear-gradient(135deg,rgba(2,98,168,.87) 0%,rgba(3,105,161,.80) 40%,rgba(14,165,233,.60) 75%,rgba(56,189,248,.40) 100%),
    url('https://images.unsplash.com/photo-1567113463300-102a7eb3cb26?w=1600&auto=format&fit=crop&q=80') center/cover no-repeat;""")
            count += 1
            print("✓ Fixed hero background (alternate method)")

# ══════════════════════════════════════════════════════════════════════
# FIX 2: Apply sky blue theme to app/portal dashboards
# Update the app CSS variables to match the landing page theme
# ══════════════════════════════════════════════════════════════════════

DASHBOARD_CSS = """

/* ════════════════════════════════════════════════════════════
   DASHBOARD THEME UPDATE — Sky Blue Laundry Theme
   Applied to Admin, Seller, and Customer Portal
════════════════════════════════════════════════════════════ */

/* ── Updated app dark palette with sky blue accents ── */
body:not(.lf-light) {
  --bg:        #071525;
  --sidebar:   #050f1c;
  --surface:   #0a1e36;
  --card:      #0d2540;
  --border:    #153550;
  --accent:    #38bdf8;
  --accent2:   #0ea5e9;
  --btn:       #0284c7;
  --btn-hover: #0369a1;
  --text:      #f0f9ff;
  --text-muted:#90c4e4;
  --text-dim:  #4a7fa8;
  --success:   #34d399;
  --warn:      #fbbf24;
  --danger:    #fb7185;
  --bubble-me: #0284c7;
}

/* ── Dashboard background ── */
body:not(.lf-light) .content,
body:not(.lf-light) #pgContent {
  background: var(--bg);
}

/* ── Sidebar sky blue theme ── */
body:not(.lf-light) .sidebar {
  background: linear-gradient(180deg, #050f1c 0%, #071525 100%);
  border-right: 1px solid #153550;
}
.sb-brand { border-bottom: 1px solid rgba(56,189,248,.15) !important; }
.sb-brand-inner { position: relative; }
.sb-logo span { color: #38bdf8 !important; }

/* ── Nav items sky blue active state ── */
body:not(.lf-light) .nav-item.active {
  background: rgba(56,189,248,.12) !important;
  border-left-color: #38bdf8 !important;
  color: #38bdf8 !important;
}
body:not(.lf-light) .nav-item:hover {
  background: rgba(56,189,248,.07) !important;
  color: #90c4e4 !important;
}

/* ── Stat cards with sky blue accent ── */
body:not(.lf-light) .sc {
  background: linear-gradient(135deg, #0d2540 0%, #0a1e36 100%);
  border: 1px solid #153550;
  border-radius: 14px;
  transition: all .2s;
}
body:not(.lf-light) .sc:hover {
  border-color: rgba(56,189,248,.3);
  box-shadow: 0 8px 24px rgba(2,132,199,.15);
  transform: translateY(-2px);
}
body:not(.lf-light) .sc-val { color: #f0f9ff; }

/* ── Cards ── */
body:not(.lf-light) .card {
  background: #0d2540;
  border: 1px solid #153550;
  border-radius: 14px;
  overflow: hidden;
}
body:not(.lf-light) .card:hover {
  border-color: rgba(56,189,248,.25);
  box-shadow: 0 6px 20px rgba(2,132,199,.1);
}
body:not(.lf-light) .ch {
  background: rgba(56,189,248,.06);
  border-bottom: 1px solid #153550;
}
body:not(.lf-light) .ch h4 { color: #90c4e4; font-weight: 700; }

/* ── Topbar ── */
body:not(.lf-light) .topbar {
  background: linear-gradient(90deg, #050f1c, #071525);
  border-bottom: 1px solid rgba(56,189,248,.15);
}
body:not(.lf-light) .tb-title { color: #38bdf8 !important; }

/* ── Tables ── */
body:not(.lf-light) th {
  background: rgba(56,189,248,.08) !important;
  color: #90c4e4 !important;
  border-bottom: 1px solid #153550;
}
body:not(.lf-light) td { color: #e0f2fe; border-bottom: 1px solid #0d2540; }
body:not(.lf-light) tbody tr:hover td { background: rgba(56,189,248,.05) !important; }

/* ── Buttons in dashboard ── */
body:not(.lf-light) .btn-primary {
  background: linear-gradient(135deg, #0ea5e9, #0369a1) !important;
  border: none !important;
  box-shadow: 0 3px 12px rgba(2,132,199,.35) !important;
}
body:not(.lf-light) .btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(2,132,199,.5) !important;
}

/* ── Badges ── */
.b-blue { background: rgba(56,189,248,.18) !important; color: #38bdf8 !important; }
.s-PENDING     { background: rgba(148,163,184,.15) !important; color: #94a3b8 !important; }
.s-RECEIVED    { background: rgba(56,189,248,.18) !important; color: #38bdf8 !important; }
.s-PROCESSING  { background: rgba(251,191,36,.15) !important; color: #fbbf24 !important; }
.s-READY       { background: rgba(52,211,153,.15) !important; color: #34d399 !important; }
.s-RELEASED    { background: rgba(167,139,250,.15) !important; color: #c4b5fd !important; }

/* ── Modals ── */
body:not(.lf-light) .modal-inner,
body:not(.lf-light) .ov > div {
  background: #0a1e36 !important;
  border: 1px solid #153550 !important;
  border-radius: 20px !important;
}
body:not(.lf-light) .modal h3 { color: #38bdf8 !important; }

/* ── Form inputs in dashboard ── */
body:not(.lf-light) .fg input,
body:not(.lf-light) .fg select,
body:not(.lf-light) .fg textarea {
  background: #071525 !important;
  border: 1.5px solid #153550 !important;
  color: #e0f2fe !important;
  border-radius: 10px;
  transition: border-color .2s;
}
body:not(.lf-light) .fg input:focus,
body:not(.lf-light) .fg select:focus {
  border-color: #38bdf8 !important;
  box-shadow: 0 0 0 3px rgba(56,189,248,.12) !important;
}

/* ── Search box ── */
body:not(.lf-light) .search-box {
  background: #071525 !important;
  border: 1.5px solid #153550 !important;
  color: #e0f2fe !important;
}
body:not(.lf-light) .search-box:focus {
  border-color: #38bdf8 !important;
}

/* ── Customer portal ── */
body:not(.lf-light) .pt-nav {
  background: linear-gradient(90deg, #050f1c, #071525) !important;
  border-bottom: 1px solid rgba(56,189,248,.15) !important;
}
body:not(.lf-light) .pt-tab {
  color: #90c4e4 !important;
  font-weight: 700;
}
body:not(.lf-light) .pt-tab.active {
  color: #38bdf8 !important;
  border-bottom-color: #38bdf8 !important;
}
body:not(.lf-light) .ord-card {
  background: #0d2540 !important;
  border: 1px solid #153550 !important;
  border-radius: 16px !important;
}
body:not(.lf-light) .ord-card:hover {
  border-color: rgba(56,189,248,.35) !important;
  box-shadow: 0 6px 20px rgba(2,132,199,.12) !important;
}

/* ── Loyalty card ── */
.loyalty-card {
  background: linear-gradient(135deg, #0369a1 0%, #0284c7 50%, #0ea5e9 100%) !important;
  border-radius: 20px !important;
  box-shadow: 0 8px 32px rgba(2,132,199,.4) !important;
}

/* ── Progress bar ── */
body:not(.lf-light) .pbar { background: rgba(56,189,248,.12) !important; }
.pbar-fill { background: linear-gradient(90deg, #0ea5e9, #38bdf8) !important; }

/* ── Notification bell ── */
.notif-bell {
  border: 1.5px solid rgba(56,189,248,.25) !important;
  color: #90c4e4 !important;
  border-radius: 10px !important;
}
.notif-bell:hover {
  border-color: #38bdf8 !important;
  color: #38bdf8 !important;
  background: rgba(56,189,248,.08) !important;
}

/* ── Messaging ── */
body:not(.lf-light) .msg-wrap { background: #071525 !important; }
body:not(.lf-light) .msg-list-item { border-bottom: 1px solid #153550 !important; }
body:not(.lf-light) .msg-list-item.active,
body:not(.lf-light) .msg-list-item:hover {
  background: rgba(56,189,248,.08) !important;
}
body:not(.lf-light) .msg-theirs {
  background: #0d2540 !important;
  border: 1px solid #153550 !important;
}
.msg-mine { background: linear-gradient(135deg, #0284c7, #0369a1) !important; }
body:not(.lf-light) .msg-input-row {
  background: #0a1e36 !important;
  border-top: 1px solid #153550 !important;
}
body:not(.lf-light) .msg-input-row input {
  background: #071525 !important;
  border: 1.5px solid #153550 !important;
  color: #e0f2fe !important;
  border-radius: 50px !important;
}
body:not(.lf-light) .msg-input-row input:focus {
  border-color: #38bdf8 !important;
}

/* ── RFID timeline ── */
body:not(.lf-light) .tl-line { background: linear-gradient(180deg, #0ea5e9, #153550) !important; }
body:not(.lf-light) .tl-fut { background: #0d2540 !important; color: #4a7fa8 !important; }

/* ── App theme btn ── */
.app-theme-btn {
  border: 1.5px solid rgba(56,189,248,.25) !important;
  color: #90c4e4 !important;
  border-radius: 8px !important;
  font-weight: 700;
}
.app-theme-btn:hover {
  border-color: #38bdf8 !important;
  color: #38bdf8 !important;
}

/* ── Light mode dashboard ── */
body.lf-light {
  --bg:#f0f9ff; --sidebar:#ffffff; --surface:#ffffff; --card:#ffffff;
  --border:#bae6fd; --accent:#0284c7; --accent2:#0369a1;
  --btn:#0284c7; --btn-hover:#0369a1;
  --text:#0c1a2e; --text-muted:#334155; --text-dim:#64748b;
  --success:#059669; --warn:#b45309; --danger:#dc2626;
  --bubble-me:#0284c7;
}
body.lf-light .sidebar { box-shadow: 1px 0 0 #bae6fd; }
body.lf-light .topbar { border-bottom: 1px solid #bae6fd; }
body.lf-light .sc { background:#fff; border: 1.5px solid #bae6fd; border-radius:14px; }
body.lf-light .sc-val { color:#0c1a2e; }
body.lf-light .card { background:#fff; border: 1px solid #bae6fd; border-radius:14px; }
body.lf-light .ch { background:#f0f9ff; border-bottom: 1px solid #bae6fd; }
body.lf-light .ch h4 { color:#0284c7; }
body.lf-light th { background:#e0f2fe !important; color:#334155 !important; }
body.lf-light td { color:#0c1a2e; }
body.lf-light .nav-item.active { background:rgba(2,132,199,.1) !important; border-left-color:#0284c7 !important; color:#0284c7 !important; }
body.lf-light .tb-title { color:#0284c7 !important; }
"""

# Find the final </style> and inject dashboard CSS
style_end = content.rfind('</style>')
if style_end != -1:
    content = content[:style_end] + DASHBOARD_CSS + '\n' + content[style_end:]
    count += 1
    print("✓ Injected dashboard sky blue theme CSS")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"\nTotal: {count+1} changes applied")
print("✅ Done!")
