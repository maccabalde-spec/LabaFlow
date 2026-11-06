"""Inject the redesign CSS directly into the <style> block."""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

NEW_CSS = r"""
/* ══════════════════════════════════════════════════════════════
   LABAFLOW REDESIGN — Sky Blue / White / Black Bubble Theme
   Overrides landing page palette for a fresh, professional look
══════════════════════════════════════════════════════════════ */

/* ── Updated CSS Variables ── */
:root {
  --lp-bg:      #f0f8ff;
  --lp-white:   #ffffff;
  --lp-text:    #0f172a;
  --lp-muted:   #475569;
  --lp-subtle:  #e0f2fe;
  --lp-border:  #bae6fd;
  --lp-accent:  #0ea5e9;
  --lp-accent2: #0284c7;
  --lp-accent3: #7dd3fc;
  --lp-navy:    #0c1a2e;
}

/* ── Bubble animations ── */
@keyframes bubbleFloat {
  0%,100% { transform: translateY(0) scale(1); }
  50%     { transform: translateY(-20px) scale(1.04); }
}
@keyframes bubblePop {
  0%   { transform: scale(0); opacity: 0; }
  60%  { opacity: .4; }
  100% { transform: scale(2); opacity: 0; }
}

/* ── Navbar ── */
.lp-nav {
  position: sticky; top: 0; z-index: 100;
  background: rgba(255,255,255,.96);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(14,165,233,.15);
  padding: 0 5vw; height: 68px;
  display: flex; align-items: center; justify-content: space-between;
  box-shadow: 0 2px 20px rgba(14,165,233,.1);
}
.lp-nav-logo {
  font-size: 22px; font-weight: 900;
  color: var(--lp-text); letter-spacing: -.8px; text-decoration: none;
}
.lp-nav-logo span { color: var(--lp-accent); }
.lp-nav-links a {
  font-size: 13px; font-weight: 600; color: var(--lp-muted);
  text-decoration: none; transition: color .2s;
}
.lp-nav-links a:hover { color: var(--lp-accent); }
.lp-btn {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 9px 22px; border-radius: 50px;
  font-size: 13px; font-weight: 700; cursor: pointer;
  transition: all .2s; text-decoration: none; border: none;
}
.lp-btn-outline {
  background: transparent; color: var(--lp-accent);
  border: 2px solid var(--lp-accent);
}
.lp-btn-outline:hover {
  background: var(--lp-accent); color: #fff;
  box-shadow: 0 4px 16px rgba(14,165,233,.3);
}
.lp-btn-solid {
  background: linear-gradient(135deg, var(--lp-accent), var(--lp-accent2));
  color: #fff; box-shadow: 0 4px 16px rgba(14,165,233,.3);
}
.lp-btn-solid:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(14,165,233,.4);
}
.lp-btn-lg { padding: 15px 36px; font-size: 15px; border-radius: 50px; }

/* ── Hero wrapper with background ── */
.lp-hero-wrapper {
  position: relative; overflow: hidden;
  background: linear-gradient(160deg, #0369a1 0%, #0ea5e9 40%, #38bdf8 70%, #e0f2fe 100%);
  min-height: 620px;
}
.lp-hero-bg-img {
  position: absolute; bottom: 0; left: 0; right: 0;
  width: 100%; height: 75%;
  object-fit: cover; object-position: bottom center;
  opacity: .12; pointer-events: none;
  mix-blend-mode: luminosity;
}
/* Animated bubbles in hero */
.lp-bubble-deco {
  position: absolute; border-radius: 50%;
  background: rgba(255,255,255,.12);
  pointer-events: none;
  animation: bubbleFloat 8s ease-in-out infinite;
}
.lp-bubble-deco:nth-child(1) { width:260px;height:260px;top:-60px;right:12%;animation-delay:-1s; }
.lp-bubble-deco:nth-child(2) { width:180px;height:180px;top:30%;right:4%;animation-delay:-3s; }
.lp-bubble-deco:nth-child(3) { width:120px;height:120px;bottom:8%;left:8%;animation-delay:-5s; }
.lp-bubble-deco:nth-child(4) { width:80px;height:80px;bottom:20%;left:22%;animation-delay:-7s; }

.lp-hero {
  padding: 90px 5vw 80px;
  display: flex; align-items: center; justify-content: space-between;
  gap: 40px; max-width: 1200px; margin: 0 auto;
  position: relative; z-index: 1;
}
.lp-hero-left { flex: 1; max-width: 580px; }
.lp-hero-eyebrow {
  display: inline-flex; align-items: center; gap: 7px;
  background: rgba(255,255,255,.92);
  color: var(--lp-accent2);
  font-size: 11px; font-weight: 800;
  padding: 6px 14px; border-radius: 50px;
  margin-bottom: 20px; letter-spacing: .6px; text-transform: uppercase;
  border: 1px solid rgba(255,255,255,.6);
  box-shadow: 0 2px 12px rgba(0,0,0,.1);
}
.lp-hero-eyebrow span {
  width: 7px; height: 7px; background: var(--lp-accent);
  border-radius: 50%; display: inline-block;
  box-shadow: 0 0 0 3px rgba(14,165,233,.3);
}
.lp-hero h1 {
  font-size: clamp(38px,5vw,64px); font-weight: 900;
  line-height: 1.04; letter-spacing: -2px;
  color: #fff; margin-bottom: 20px;
  text-shadow: 0 2px 24px rgba(2,132,199,.4);
}
.lp-hero h1 em { font-style: normal; color: #fff; opacity: .95; }
.lp-hero p {
  font-size: 17px; color: rgba(255,255,255,.92);
  line-height: 1.7; margin-bottom: 32px; max-width: 480px;
}
.lp-hero-actions { display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
.lp-hero-note {
  display: flex; gap: 10px; flex-wrap: wrap; margin-top: 20px;
}
.lp-hero-note-item {
  display: inline-flex; align-items: center; gap: 5px;
  background: rgba(255,255,255,.18);
  color: #fff; font-size: 12px; font-weight: 600;
  padding: 5px 12px; border-radius: 50px;
  border: 1px solid rgba(255,255,255,.3);
  backdrop-filter: blur(4px);
}
.lp-hero-right { flex: 0 0 420px; max-width: 420px; }
.lp-hero-card {
  background: rgba(255,255,255,.97);
  border-radius: 24px; padding: 28px;
  box-shadow: 0 24px 64px rgba(2,132,199,.3), 0 4px 16px rgba(0,0,0,.1);
  border: 1px solid rgba(255,255,255,.8);
  backdrop-filter: blur(16px);
}
.lp-hero-card-title {
  font-size: 14px; font-weight: 800; color: var(--lp-text) !important;
  margin-bottom: 14px;
  padding-bottom: 12px; border-bottom: 2px solid var(--lp-subtle);
  display: flex; align-items: center; gap: 8px;
}
.price-row { display: flex; justify-content: space-between; align-items: center; padding: 10px 0; border-bottom: 1px solid var(--lp-border) !important; }
.price-row:last-child { border-bottom: none !important; }
.price-row-label { font-size: 13px; font-weight: 600; color: var(--lp-text) !important; }
.price-row-sub { font-size: 11px; color: var(--lp-muted) !important; margin-top: 1px; }
.price-row-val { font-size: 16px; font-weight: 800; color: var(--lp-accent) !important; }

/* ── Section headings ── */
.lp-eyebrow {
  font-size: 12px; font-weight: 800; color: var(--lp-accent);
  text-transform: uppercase; letter-spacing: 1.2px; margin-bottom: 10px;
  display: inline-flex; align-items: center; gap: 8px;
}
.lp-eyebrow::before {
  content: ''; width: 24px; height: 3px;
  background: linear-gradient(90deg, var(--lp-accent), var(--lp-accent3));
  border-radius: 2px;
}
.lp-section-title {
  font-size: clamp(30px,3.5vw,44px); font-weight: 900;
  letter-spacing: -1.2px; color: var(--lp-text); margin-bottom: 14px; line-height: 1.1;
}
.lp-section { padding: 90px 5vw; max-width: 1200px; margin: 0 auto; }

/* ── How It Works Steps ── */
.lp-steps { display: grid; grid-template-columns: repeat(4,1fr); gap: 24px; margin-top: 48px; }
.lp-step {
  background: var(--lp-white);
  border-radius: 24px; overflow: hidden;
  border: 1.5px solid var(--lp-border);
  transition: all .3s ease;
  box-shadow: 0 4px 20px rgba(14,165,233,.08);
}
.lp-step:hover {
  transform: translateY(-8px);
  box-shadow: 0 20px 52px rgba(14,165,233,.2);
  border-color: var(--lp-accent);
}
.lp-step-img {
  width: 100%; height: 160px;
  object-fit: cover; display: block;
  transition: transform .4s ease;
}
.lp-step:hover .lp-step-img { transform: scale(1.05); }
.lp-step-img-placeholder {
  width: 100%; height: 160px;
  display: flex; align-items: center; justify-content: center;
  background: linear-gradient(135deg, var(--lp-subtle), var(--lp-border));
  font-size: 56px;
}
.lp-step-body { padding: 20px 20px 24px; }
.lp-step-num {
  display: inline-flex; align-items: center; justify-content: center;
  width: 30px; height: 30px; border-radius: 50%;
  background: linear-gradient(135deg, var(--lp-accent), var(--lp-accent2));
  color: #fff; font-size: 12px; font-weight: 800; margin-bottom: 12px;
  box-shadow: 0 2px 8px rgba(14,165,233,.4);
}
.lp-step-icon { font-size: 26px; margin-bottom: 8px; display: block; }
.lp-step h4 { font-size: 15px; font-weight: 800; color: var(--lp-text); margin-bottom: 6px; }
.lp-step p  { font-size: 13px; color: var(--lp-muted); line-height: 1.6; }

/* ── Services ── */
.lp-services-bg {
  background: linear-gradient(160deg, #0c1a2e 0%, #0369a1 55%, #0ea5e9 100%);
  position: relative; overflow: hidden;
}
.lp-services-bg::before {
  content: '';
  position: absolute; inset: 0;
  background: radial-gradient(ellipse at 80% 50%, rgba(14,165,233,.15) 0%, transparent 70%);
  pointer-events: none;
}
.lp-services-inner { padding: 90px 5vw; max-width: 1200px; margin: 0 auto; position: relative; }
.lp-services-grid { display: grid; grid-template-columns: repeat(3,1fr); gap: 20px; margin-top: 48px; }
.lp-svc {
  background: rgba(255,255,255,.08);
  border: 1px solid rgba(255,255,255,.15);
  border-radius: 20px; padding: 28px 24px;
  transition: all .3s; backdrop-filter: blur(8px);
}
.lp-svc:hover {
  background: rgba(255,255,255,.16);
  border-color: rgba(255,255,255,.4);
  transform: translateY(-5px);
  box-shadow: 0 16px 40px rgba(0,0,0,.25);
}
.lp-svc-icon {
  font-size: 32px; margin-bottom: 14px;
  display: flex; align-items: center; justify-content: center;
  width: 60px; height: 60px; border-radius: 18px;
  background: rgba(255,255,255,.15);
}
.lp-svc h4 { font-size: 16px; font-weight: 800; color: #fff; margin-bottom: 8px; }
.lp-svc p  { font-size: 13px; color: rgba(255,255,255,.75); line-height: 1.6; }
.lp-svc-badge {
  display: inline-block; margin-top: 12px; padding: 4px 12px;
  background: rgba(255,255,255,.2); color: #fff;
  border-radius: 50px; font-size: 11px; font-weight: 700;
  border: 1px solid rgba(255,255,255,.3);
}

/* ── Pricing ── */
.lp-pricing-grid { display: grid; grid-template-columns: repeat(3,1fr); gap: 24px; margin-top: 48px; }
.lp-price-card {
  background: var(--lp-white);
  border: 2px solid var(--lp-border);
  border-radius: 24px; padding: 32px 28px; transition: all .3s;
  box-shadow: 0 4px 20px rgba(14,165,233,.06);
}
.lp-price-card:hover {
  border-color: var(--lp-accent);
  transform: translateY(-5px);
  box-shadow: 0 16px 48px rgba(14,165,233,.18);
}
.lp-price-card.featured {
  border-color: var(--lp-accent);
  box-shadow: 0 12px 48px rgba(14,165,233,.25);
  background: linear-gradient(160deg, #f0f9ff 0%, #e0f2fe 100%);
  transform: scale(1.03);
}
.lp-price-card-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .5px; color: var(--lp-muted); margin-bottom: 8px; }
.lp-price-card-name  { font-size: 20px; font-weight: 800; color: var(--lp-text); margin-bottom: 4px; }
.lp-price-card-price { font-size: 40px; font-weight: 900; color: var(--lp-accent); letter-spacing: -1px; margin: 12px 0 4px; }
.lp-price-card-price sup { font-size: 20px; vertical-align: top; margin-top: 6px; }
.lp-price-card-price span { font-size: 14px; font-weight: 400; color: var(--lp-muted); }
.lp-price-card-desc { font-size: 13px; color: var(--lp-muted); margin-bottom: 20px; line-height: 1.5; }
.lp-price-features { list-style: none; margin-bottom: 24px; }
.lp-price-features li {
  display: flex; align-items: center; gap: 10px;
  font-size: 13px; color: var(--lp-text);
  padding: 8px 0; border-bottom: 1px solid var(--lp-border);
}
.lp-price-features li:last-child { border-bottom: none; }
.lp-price-features li::before {
  content: '✓'; color: var(--lp-accent); font-weight: 900;
  flex-shrink: 0; font-size: 14px;
}
.lp-price-feat-badge {
  display: inline-block; background: #dbeafe; color: #1d4ed8;
  font-size: 10px; font-weight: 700; padding: 2px 7px;
  border-radius: 4px; margin-left: 4px;
}

/* ── Reviews ── */
.lp-reviews-grid { display: grid; grid-template-columns: repeat(3,1fr); gap: 20px; margin-top: 48px; }
.lp-review {
  background: var(--lp-white);
  border: 1.5px solid var(--lp-border);
  border-radius: 20px; padding: 26px 24px; transition: all .2s;
  box-shadow: 0 2px 12px rgba(14,165,233,.06);
}
.lp-review:hover {
  border-color: var(--lp-accent);
  transform: translateY(-3px);
  box-shadow: 0 10px 32px rgba(14,165,233,.14);
}
.lp-review-stars { color: #f59e0b; font-size: 14px; margin-bottom: 10px; letter-spacing: 2px; }
.lp-review-text { font-size: 14px; color: var(--lp-text); line-height: 1.6; margin-bottom: 16px; font-style: italic; }

/* ── CTA Banner ── */
.lp-cta-bg {
  background: linear-gradient(135deg, #0c1a2e 0%, #0369a1 45%, #0ea5e9 100%);
  padding: 80px 5vw; text-align: center; position: relative; overflow: hidden;
}
.lp-cta-bg::before, .lp-cta-bg::after {
  content: '';
  position: absolute; border-radius: 50%;
  background: rgba(255,255,255,.06); pointer-events: none;
}
.lp-cta-bg::before { width: 400px; height: 400px; top: -150px; right: -80px; }
.lp-cta-bg::after  { width: 300px; height: 300px; bottom: -120px; left: -60px; }
.lp-cta-bg h2 { font-size: clamp(28px,4vw,44px); font-weight: 900; color: #fff; letter-spacing: -.8px; margin-bottom: 14px; position: relative; }
.lp-cta-bg p  { font-size: 16px; color: rgba(255,255,255,.85); margin-bottom: 32px; position: relative; }
.lp-btn-white {
  background: #fff; color: var(--lp-accent2); font-weight: 800;
  box-shadow: 0 8px 32px rgba(0,0,0,.2); position: relative;
}
.lp-btn-white:hover {
  background: #f0f9ff; color: var(--lp-accent);
  transform: translateY(-3px); box-shadow: 0 14px 44px rgba(0,0,0,.3);
}

/* ── FAQ ── */
.lp-faq-q { cursor: pointer; font-size: 15px; font-weight: 700; color: var(--lp-text); display: flex; justify-content: space-between; align-items: center; padding: 20px 4px; }
.lp-faq-q:hover { color: var(--lp-accent); }
.lp-faq-icon { color: var(--lp-muted); transition: transform .2s; font-size: 20px; }
.lp-faq-item.open .lp-faq-icon { transform: rotate(45deg); color: var(--lp-accent); }
.lp-faq-a { display: none; padding: 0 4px 20px; font-size: 14px; color: var(--lp-muted); line-height: 1.65; }
.lp-faq-item.open .lp-faq-a { display: block; }
.lp-faq-item { border-bottom: 1px solid var(--lp-border); }

/* ── Badges strip ── */
.lp-badges { background: var(--lp-navy); padding: 16px 5vw; display: flex; align-items: center; justify-content: center; gap: 40px; flex-wrap: wrap; }
.lp-badge-item { display: flex; align-items: center; gap: 10px; color: rgba(255,255,255,.85); font-size: 13px; font-weight: 600; }

/* ── Dark mode adjustments ── */
body.lf-dark .lp-hero-wrapper { background: linear-gradient(160deg,#0a1628 0%,#0c2340 50%,#051020 100%); }
body.lf-dark .lp-hero h1      { color: #e2e8f0; }
body.lf-dark .lp-hero p       { color: rgba(226,232,240,.85); }
body.lf-dark .lp-step          { background: #161b22; border-color: #21395a; }
body.lf-dark .lp-step h4       { color: #e6edf3; }
body.lf-dark .lp-step p        { color: #8b949e; }
body.lf-dark .lp-price-card    { background: #161b22 !important; border-color: #21395a !important; }
body.lf-dark .lp-price-card.featured { background: #0d2137 !important; }
body.lf-dark .lp-price-card-name { color: #e6edf3 !important; }
body.lf-dark .lp-price-card-desc,
body.lf-dark .lp-price-features li { color: #c9d1d9 !important; }
body.lf-dark .lp-review { background: #161b22; border-color: #21395a; }
body.lf-dark .lp-hero-note-item { background: rgba(255,255,255,.08); }
"""

# Find the closing </style> tag and insert our CSS just before it
# Find the first </style> tag (end of the main styles block)
style_end = content.find('</style>')
if style_end != -1:
    content = content[:style_end] + NEW_CSS + '\n' + content[style_end:]
    print("✓ Injected redesign CSS block")
else:
    print("ERROR: </style> not found")

# ── Also add bubble decorations to hero wrapper HTML ──────────────────
old_wrapper = """  <div class="lp-hero-wrapper">
    <div class="lp-hero-bubbles"></div>"""

new_wrapper = """  <div class="lp-hero-wrapper">
    <div class="lp-bubble-deco"></div>
    <div class="lp-bubble-deco"></div>
    <div class="lp-bubble-deco"></div>
    <div class="lp-bubble-deco"></div>"""

if old_wrapper in content:
    content = content.replace(old_wrapper, new_wrapper)
    print("✓ Added bubble decorations to hero")

# ── Fix hero note — replace old plain text with note-items ────────────
import re

old_note = '      <div class="lp-hero-note">✅ Walk-in welcome &nbsp;·&nbsp; 💳 GCash & Cash accepted &nbsp;·&nbsp; 📡 RFID-tracked</div>'
new_note = '''      <div class="lp-hero-note">
        <span class="lp-hero-note-item">✅ Walk-in welcome</span>
        <span class="lp-hero-note-item">💳 GCash &amp; Cash</span>
        <span class="lp-hero-note-item">📡 RFID-tracked</span>
      </div>'''

if old_note in content:
    content = content.replace(old_note, new_note)
    print("✓ Updated hero note items")

# ── Fix hero action buttons (white on blue bg) ────────────────────────
old_actions = '        <button class="lp-btn lp-btn-solid lp-btn-lg" onclick="openAuth(\'reg\')">Book a Service</button>\n\n        <button class="lp-btn lp-btn-outline lp-btn-lg" onclick="document.getElementById(\'how\').scrollIntoView({behavior:\'smooth\'})">How It Works</button>'
new_actions = '        <button class="lp-btn lp-btn-lg" style="background:#fff;color:var(--lp-accent2);font-weight:800;box-shadow:0 8px 32px rgba(0,0,0,.2);" onclick="openAuth(\'reg\')">🧺 Book a Service</button>\n\n        <button class="lp-btn lp-btn-lg" style="background:rgba(255,255,255,.15);color:#fff;border:2px solid rgba(255,255,255,.5);backdrop-filter:blur(4px);" onclick="document.getElementById(\'how\').scrollIntoView({behavior:\'smooth\'})">How It Works ↓</button>'
if old_actions in content:
    content = content.replace(old_actions, new_actions)
    print("✓ Updated hero action buttons")

# ── Fix remaining 2 steps that weren't replaced (Step 02, Step 04) ───
# Step 02 RFID
step02_old = '      <div class="lp-step">\n\n        <div class="lp-step-num">Step 02</div>\n\n        <span class="lp-step-icon">📡</span>\n\n        <h4>RFID Tag Assigned</h4>\n\n        <p>Your laundry gets a unique RFID tag. We scan it to receive your items — your order is now tracked in real-time.</p>\n\n      </div>'
step02_new = '''      <div class="lp-step">
        <img class="lp-step-img" loading="lazy"
          src="https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=400&auto=format&fit=crop&q=70"
          alt="Laundry basket drop off"
          onerror="this.style.display='none';this.nextElementSibling.style.display='flex';"
        >
        <div class="lp-step-img-placeholder" style="display:none;">📡</div>
        <div class="lp-step-body">
          <div class="lp-step-num">02</div>
          <span class="lp-step-icon">📡</span>
          <h4>RFID Tag Assigned</h4>
          <p>Your laundry gets a unique RFID tag. We scan it to receive your items — your order is now tracked in real-time.</p>
        </div>
      </div>'''
if step02_old in content:
    content = content.replace(step02_old, step02_new)
    print("✓ Updated Step 02")

# Step 04 Pickup — handle encoding variant
for step04_old in [
    "      <div class=\"lp-step\">\n\n        <div class=\"lp-step-num\">Step 04</div>\n\n        <span class=\"lp-step-icon\">\u2705</span>\n\n        <h4>Ready for Pickup</h4>\n\n        <p>You'll be notified when your laundry is ready. Pick up and pay \u2014 or earn loyalty points with every order!</p>\n\n      </div>",
]:
    if step04_old in content:
        content = content.replace(step04_old, '''      <div class="lp-step">
        <img class="lp-step-img" loading="lazy"
          src="https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=400&auto=format&fit=crop&q=70"
          alt="Clean folded laundry ready for pickup"
          onerror="this.style.display='none';this.nextElementSibling.style.display='flex';"
        >
        <div class="lp-step-img-placeholder" style="display:none;">✅</div>
        <div class="lp-step-body">
          <div class="lp-step-num">04</div>
          <span class="lp-step-icon">✅</span>
          <h4>Ready for Pickup</h4>
          <p>You\'ll be notified when your laundry is ready. Pick up and pay — or earn loyalty points with every order!</p>
        </div>
      </div>''')
        print("✓ Updated Step 04")
        break

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ CSS injection complete!")
