"""
Complete landing page redesign fix.
Sky blue / white / black bubble theme.
"""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# ── Step 1: Remove ALL previous redesign CSS injected at top ─────────────
# Find and remove the big injected block
marker_start = '/* ══════════════════════════════════════════════════════════════\n   LABAFLOW REDESIGN'
marker_end   = '/* ── Dark mode adjustments ──'
dark_end     = 'body.lf-dark .lp-hero-note-item { background: rgba(255,255,255,.08); }\n'

start_idx = content.find(marker_start)
end_idx   = content.find(dark_end)
if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + content[end_idx + len(dark_end):]
    print("✓ Removed old injected CSS")

# Also remove the @keyframes block that was added before
kf = '\n/* ── Bubble float animations ── */\n@keyframes bubbleFloat {'
kf_end = '}\n/* ── Bubble float animations ── */\n@keyframes bubbleFloat {'
old_kf_block = '''\n/* ── Bubble animations ── */\n@keyframes bubbleFloat {\n  0%,100% { transform: translateY(0) scale(1); }\n  50%     { transform: translateY(-20px) scale(1.04); }\n}\n@keyframes bubblePop {\n  0%   { transform: scale(0); opacity: 0; }\n  60%  { opacity: .4; }\n  100% { transform: scale(2); opacity: 0; }\n}'''
content = content.replace(old_kf_block, '')

# ── Step 2: Fix :root variables back to clean state then update ──────────
old_root_search = '--lp-bg:      #f0f8ff;'
new_root = '''  /* ── LabaFlow 2.0 — Sky Blue Bubble Theme ── */
  --lp-bg:      #f5fbff;
  --lp-white:   #ffffff;
  --lp-text:    #0f172a;
  --lp-muted:   #334155;
  --lp-subtle:  #e0f2fe;
  --lp-border:  #7dd3fc;
  --lp-accent:  #0284c7;
  --lp-accent2: #0369a1;
  --lp-accent3: #38bdf8;
  --lp-navy:    #0c1a2e;'''
if old_root_search in content:
    # Already has updated vars, just keep them
    print("✓ Root vars already updated")
else:
    print("⚠ Root vars not found, skipping")

# ── Step 3: Inject one clean CSS block just before </style> ──────────────
NEW_CSS = '''
/* ════════════════════════════════════════════════════════════
   LABAFLOW FINAL REDESIGN — Sky Blue Bubble Laundry Theme
   All landing page styles override. App dashboard untouched.
════════════════════════════════════════════════════════════ */

/* Google Fonts */
@import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800;900&display=swap');

/* Root palette */
:root {
  --lp-bg:      #f0f9ff;
  --lp-white:   #ffffff;
  --lp-text:    #0c1a2e;
  --lp-muted:   #334155;
  --lp-subtle:  #e0f2fe;
  --lp-border:  #7dd3fc;
  --lp-accent:  #0284c7;
  --lp-accent2: #0369a1;
  --lp-accent3: #38bdf8;
  --lp-navy:    #0c1a2e;
}

/* ── Bubble float animation ── */
@keyframes lf-float {
  0%,100% { transform: translateY(0) scale(1); }
  50%     { transform: translateY(-18px) scale(1.06); }
}
@keyframes lf-bob {
  0%,100% { transform: translateY(0); }
  50%     { transform: translateY(-10px); }
}

/* Body font */
#landing, #landing * { font-family: 'Nunito', 'Segoe UI', system-ui, sans-serif; }

/* Fix portal not hidden behind landing */
#landing { display: block; position: relative; z-index: 10; }
#app     { display: none; }
#portal  { display: none; }

/* ── NAVBAR ── */
.lp-nav {
  position: sticky; top: 0; z-index: 200;
  background: rgba(255,255,255,.97);
  backdrop-filter: blur(16px);
  border-bottom: 2px solid #e0f2fe;
  padding: 0 6vw; height: 70px;
  display: flex; align-items: center; justify-content: space-between;
  box-shadow: 0 4px 24px rgba(2,132,199,.12);
}
.lp-nav-logo {
  font-size: 24px; font-weight: 900; font-family: 'Nunito', sans-serif;
  color: #0c1a2e; letter-spacing: -1px; text-decoration: none;
  display: flex; align-items: center; gap: 8px;
}
.lp-nav-logo::before { content: '🫧'; font-size: 22px; }
.lp-nav-logo span { color: #0284c7; }
.lp-nav-links { display: flex; align-items: center; gap: 28px; }
.lp-nav-links a {
  font-size: 14px; font-weight: 700; color: #334155;
  text-decoration: none; transition: color .2s; font-family: 'Nunito', sans-serif;
}
.lp-nav-links a:hover { color: #0284c7; }
.lp-nav-cta { display: flex; gap: 10px; align-items: center; }

/* ── BUTTONS ── */
.lp-btn {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 10px 24px; border-radius: 50px;
  font-size: 14px; font-weight: 800; cursor: pointer;
  transition: all .25s cubic-bezier(.34,1.56,.64,1);
  text-decoration: none; border: none; font-family: 'Nunito', sans-serif;
}
.lp-btn-outline {
  background: transparent; color: #0284c7;
  border: 2.5px solid #0284c7;
}
.lp-btn-outline:hover {
  background: #0284c7; color: #fff;
  box-shadow: 0 6px 20px rgba(2,132,199,.35);
  transform: translateY(-2px);
}
.lp-btn-solid {
  background: linear-gradient(135deg,#0ea5e9,#0369a1);
  color: #fff; box-shadow: 0 4px 18px rgba(2,132,199,.4);
}
.lp-btn-solid:hover {
  transform: translateY(-3px);
  box-shadow: 0 10px 30px rgba(2,132,199,.5);
}
.lp-btn-lg { padding: 15px 38px; font-size: 16px; }
.lp-btn-dark { background: #0c1a2e; color: #fff; }
.lp-btn-dark:hover { background: #1e3a5f; transform: translateY(-2px); }
.lp-btn-white { background: #fff; color: #0369a1; font-weight: 900; }
.lp-btn-white:hover {
  background: #e0f2fe; transform: translateY(-3px);
  box-shadow: 0 12px 36px rgba(0,0,0,.25);
}

/* ── HERO WRAPPER — background image ── */
.lp-hero-wrapper {
  position: relative; overflow: hidden; min-height: 620px;
  background: #0284c7 url('https://images.pexels.com/photos/5591663/pexels-photo-5591663.jpeg?auto=compress&cs=tinysrgb&w=1600') center/cover no-repeat;
}
/* Dark overlay so text is readable */
.lp-hero-wrapper::before {
  content: ''; position: absolute; inset: 0;
  background: linear-gradient(
    135deg,
    rgba(2,98,168,.88) 0%,
    rgba(3,105,161,.82) 40%,
    rgba(14,165,233,.65) 70%,
    rgba(56,189,248,.45) 100%
  );
  z-index: 0;
}
/* Floating bubble circles */
.lp-bubble-deco {
  position: absolute; border-radius: 50%;
  background: rgba(255,255,255,.1);
  border: 1px solid rgba(255,255,255,.2);
  pointer-events: none; z-index: 0;
  animation: lf-float 7s ease-in-out infinite;
}
.lp-bubble-deco:nth-child(1){ width:280px;height:280px;top:-80px;right:8%;animation-duration:7s; }
.lp-bubble-deco:nth-child(2){ width:180px;height:180px;top:50%;right:3%;animation-duration:9s;animation-delay:-3s; }
.lp-bubble-deco:nth-child(3){ width:120px;height:120px;bottom:5%;left:6%;animation-duration:6s;animation-delay:-1s; }
.lp-bubble-deco:nth-child(4){ width:70px;height:70px;bottom:25%;left:20%;animation-duration:8s;animation-delay:-5s; }

/* ── HERO CONTENT ── */
.lp-hero {
  position: relative; z-index: 1;
  padding: 90px 6vw 80px;
  display: flex; align-items: center; justify-content: space-between;
  gap: 48px; max-width: 1240px; margin: 0 auto;
}
.lp-hero-left { flex: 1; max-width: 580px; }
.lp-hero-eyebrow {
  display: inline-flex; align-items: center; gap: 8px;
  background: rgba(255,255,255,.22);
  color: #fff; font-size: 12px; font-weight: 800;
  padding: 7px 16px; border-radius: 50px;
  margin-bottom: 22px; letter-spacing: .8px; text-transform: uppercase;
  border: 1px solid rgba(255,255,255,.4);
  backdrop-filter: blur(6px); font-family: 'Nunito', sans-serif;
}
.lp-hero-eyebrow span {
  width: 8px; height: 8px; background: #fff;
  border-radius: 50%; display: inline-block;
  box-shadow: 0 0 0 3px rgba(255,255,255,.3);
  animation: lf-bob 2s ease-in-out infinite;
}
.lp-hero h1 {
  font-size: clamp(42px,5.5vw,68px); font-weight: 900;
  line-height: 1.0; letter-spacing: -2.5px;
  color: #ffffff; margin-bottom: 22px;
  font-family: 'Nunito', sans-serif;
  text-shadow: 0 4px 32px rgba(0,0,0,.25);
}
.lp-hero h1 em {
  font-style: normal; color: #bae6fd;
  border-bottom: 4px solid rgba(186,230,253,.5);
}
.lp-hero p {
  font-size: 18px; color: rgba(255,255,255,.92);
  line-height: 1.75; margin-bottom: 36px; max-width: 490px;
  font-family: 'Nunito', sans-serif; font-weight: 600;
}
.lp-hero-actions { display: flex; gap: 14px; flex-wrap: wrap; align-items: center; }
.lp-hero-note {
  display: flex; gap: 10px; flex-wrap: wrap; margin-top: 24px;
}
.lp-hero-note-item {
  display: inline-flex; align-items: center; gap: 6px;
  background: rgba(255,255,255,.15); color: #fff;
  font-size: 13px; font-weight: 700; font-family: 'Nunito', sans-serif;
  padding: 6px 14px; border-radius: 50px;
  border: 1px solid rgba(255,255,255,.35);
  backdrop-filter: blur(6px);
}
.lp-hero-right { flex: 0 0 400px; max-width: 400px; }
.lp-hero-card {
  background: #ffffff; border-radius: 24px; padding: 28px;
  box-shadow: 0 28px 72px rgba(0,0,0,.28), 0 4px 16px rgba(2,132,199,.2);
  border: 1px solid rgba(255,255,255,.9);
}
.lp-hero-card-title {
  font-size: 15px; font-weight: 900; color: #0c1a2e !important;
  margin-bottom: 16px; font-family: 'Nunito', sans-serif;
  padding-bottom: 12px; border-bottom: 2px solid #e0f2fe;
}
.price-row { display:flex; justify-content:space-between; align-items:center; padding:10px 0; border-bottom:1px solid #e0f2fe !important; }
.price-row:last-child { border-bottom:none !important; }
.price-row-label { font-size:14px; font-weight:700; color:#0c1a2e !important; font-family:'Nunito',sans-serif; }
.price-row-sub   { font-size:12px; color:#475569 !important; margin-top:2px; }
.price-row-val   { font-size:18px; font-weight:900; color:#0284c7 !important; font-family:'Nunito',sans-serif; }

/* ── Badges strip ── */
.lp-badges {
  background: #0c1a2e; padding: 18px 5vw;
  display: flex; align-items: center; justify-content: center; gap: 40px; flex-wrap: wrap;
}
.lp-badge-item { display:flex; align-items:center; gap:10px; color:rgba(255,255,255,.9); font-size:14px; font-weight:700; font-family:'Nunito',sans-serif; }

/* ── Section headings ── */
.lp-section { padding: 90px 5vw; max-width: 1200px; margin: 0 auto; }
.lp-eyebrow {
  font-size: 12px; font-weight: 900; color: #0284c7;
  text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 12px;
  display: flex; align-items: center; gap: 10px; font-family: 'Nunito', sans-serif;
}
.lp-eyebrow::before { content:''; width:28px; height:3px; background:#0284c7; border-radius:2px; }
.lp-section-title {
  font-size: clamp(32px,4vw,48px); font-weight: 900;
  letter-spacing: -1.5px; color: #0c1a2e; margin-bottom: 14px;
  line-height: 1.08; font-family: 'Nunito', sans-serif;
}
.lp-section-sub {
  font-size: 16px; color: #334155; line-height: 1.7;
  max-width: 540px; font-weight: 600; font-family: 'Nunito', sans-serif;
}

/* ── How It Works Steps ── */
.lp-steps { display:grid; grid-template-columns:repeat(4,1fr); gap:20px; margin-top:52px; }
.lp-step {
  background: #fff; border-radius: 20px; overflow: hidden;
  border: 2px solid #e0f2fe; transition: all .3s ease;
  box-shadow: 0 4px 16px rgba(2,132,199,.08);
}
.lp-step:hover {
  transform: translateY(-10px);
  box-shadow: 0 24px 56px rgba(2,132,199,.22);
  border-color: #0284c7;
}
.lp-step-img {
  width: 100%; height: 170px; object-fit: cover;
  display: block; transition: transform .5s ease;
}
.lp-step:hover .lp-step-img { transform: scale(1.07); }
.lp-step-img-placeholder {
  width: 100%; height: 170px; display: flex; align-items: center;
  justify-content: center; font-size: 60px;
  background: linear-gradient(135deg, #e0f2fe, #bae6fd);
}
.lp-step-body { padding: 20px 20px 24px; }
.lp-step-num {
  display: inline-flex; align-items: center; justify-content: center;
  width: 32px; height: 32px; border-radius: 50%;
  background: linear-gradient(135deg, #0ea5e9, #0284c7);
  color: #fff; font-size: 13px; font-weight: 900;
  margin-bottom: 12px; font-family: 'Nunito', sans-serif;
  box-shadow: 0 3px 10px rgba(2,132,199,.45);
}
.lp-step-icon { font-size: 28px; margin-bottom: 8px; display: block; }
.lp-step h4 {
  font-size: 16px; font-weight: 900; color: #0c1a2e;
  margin-bottom: 8px; font-family: 'Nunito', sans-serif;
}
.lp-step p { font-size: 13px; color: #475569; line-height: 1.65; font-weight: 600; }

/* ── Services section ── */
.lp-services-bg {
  background: linear-gradient(160deg, #0c1a2e 0%, #0369a1 60%, #0ea5e9 100%);
  position: relative; overflow: hidden;
}
.lp-services-bg::after {
  content: '';
  position: absolute; top: -100px; right: -100px;
  width: 500px; height: 500px; border-radius: 50%;
  background: rgba(255,255,255,.04); pointer-events: none;
}
.lp-services-inner { padding: 90px 5vw; max-width: 1200px; margin: 0 auto; position: relative; z-index: 1; }
.lp-services-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:20px; margin-top:52px; }
.lp-svc {
  background: rgba(255,255,255,.1);
  border: 1.5px solid rgba(255,255,255,.2);
  border-radius: 20px; padding: 28px 24px; transition: all .3s;
  backdrop-filter: blur(8px);
}
.lp-svc:hover {
  background: rgba(255,255,255,.18); border-color: rgba(255,255,255,.5);
  transform: translateY(-6px); box-shadow: 0 20px 48px rgba(0,0,0,.25);
}
.lp-svc-icon {
  font-size: 32px; margin-bottom: 16px;
  display: flex; align-items: center; justify-content: center;
  width: 64px; height: 64px; border-radius: 20px;
  background: rgba(255,255,255,.15); border: 1px solid rgba(255,255,255,.25);
}
.lp-svc h4 { font-size: 17px; font-weight: 900; color: #fff; margin-bottom: 8px; font-family: 'Nunito', sans-serif; }
.lp-svc p  { font-size: 13px; color: rgba(255,255,255,.8); line-height: 1.65; font-weight: 600; }
.lp-svc-badge {
  display: inline-block; margin-top: 14px; padding: 5px 14px;
  background: rgba(255,255,255,.2); color: #fff;
  border-radius: 50px; font-size: 12px; font-weight: 800;
  border: 1px solid rgba(255,255,255,.35); font-family: 'Nunito', sans-serif;
}

/* ── Pricing ── */
.lp-pricing-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:24px; margin-top:52px; }
.lp-price-card {
  background: #fff; border: 2.5px solid #bae6fd;
  border-radius: 24px; padding: 32px 28px; transition: all .3s;
  box-shadow: 0 4px 20px rgba(2,132,199,.07);
}
.lp-price-card:hover {
  border-color: #0284c7; transform: translateY(-6px);
  box-shadow: 0 20px 52px rgba(2,132,199,.2);
}
.lp-price-card.featured {
  border-color: #0284c7;
  box-shadow: 0 16px 56px rgba(2,132,199,.3);
  background: linear-gradient(165deg, #f0f9ff, #e0f2fe);
  transform: scale(1.04);
}
.lp-price-card-label {
  font-size: 11px; font-weight: 800; text-transform: uppercase;
  letter-spacing: 1px; color: #64748b; margin-bottom: 8px; font-family: 'Nunito', sans-serif;
}
.lp-price-card-name  { font-size: 20px; font-weight: 900; color: #0c1a2e; margin-bottom: 4px; font-family: 'Nunito', sans-serif; }
.lp-price-card-price {
  font-size: 44px; font-weight: 900; color: #0284c7;
  letter-spacing: -2px; margin: 12px 0 4px; font-family: 'Nunito', sans-serif;
}
.lp-price-card-price sup  { font-size: 22px; vertical-align: top; margin-top: 8px; }
.lp-price-card-price span { font-size: 14px; font-weight: 600; color: #64748b; }
.lp-price-card-desc { font-size: 13px; color: #475569; margin-bottom: 20px; line-height: 1.6; font-weight: 600; }
.lp-price-features { list-style: none; margin-bottom: 24px; }
.lp-price-features li {
  display: flex; align-items: center; gap: 10px;
  font-size: 13px; color: #0c1a2e; padding: 8px 0;
  border-bottom: 1px solid #e0f2fe; font-weight: 700; font-family: 'Nunito', sans-serif;
}
.lp-price-features li:last-child { border-bottom: none; }
.lp-price-features li::before { content: '✓'; color: #0284c7; font-weight: 900; font-size: 15px; flex-shrink: 0; }
.lp-price-feat-badge { display:inline-block; background:#dbeafe; color:#1e40af; font-size:10px; font-weight:800; padding:2px 8px; border-radius:4px; margin-left:4px; }

/* ── Reviews ── */
.lp-reviews-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:20px; margin-top:52px; }
.lp-review {
  background: #fff; border: 2px solid #bae6fd;
  border-radius: 20px; padding: 26px 24px; transition: all .25s;
  box-shadow: 0 3px 14px rgba(2,132,199,.08);
}
.lp-review:hover {
  border-color: #0284c7; transform: translateY(-4px);
  box-shadow: 0 12px 36px rgba(2,132,199,.16);
}
.lp-review-stars { color: #f59e0b; font-size: 15px; margin-bottom: 10px; letter-spacing: 2px; }
.lp-review-text  { font-size: 14px; color: #0f172a; line-height: 1.7; margin-bottom: 16px; font-style: italic; font-weight: 600; }
.lp-review-name  { font-size: 13px; font-weight: 900; color: #0c1a2e; }
.lp-review-loc   { font-size: 11px; color: #64748b; }
.lp-review-av    { background: #0284c7 !important; }

/* ── CTA Banner ── */
.lp-cta-bg {
  background: linear-gradient(135deg, #0c1a2e 0%, #0369a1 50%, #0ea5e9 100%);
  padding: 88px 5vw; text-align: center;
  position: relative; overflow: hidden;
}
.lp-cta-bg::before {
  content: ''; position: absolute;
  width: 500px; height: 500px; border-radius: 50%;
  background: rgba(255,255,255,.05); top: -200px; right: -100px;
  pointer-events: none;
}
.lp-cta-bg h2 {
  font-size: clamp(30px,4vw,48px); font-weight: 900; color: #fff;
  letter-spacing: -1px; margin-bottom: 14px; font-family: 'Nunito', sans-serif;
}
.lp-cta-bg p { font-size: 17px; color: rgba(255,255,255,.88); margin-bottom: 34px; font-weight: 600; }

/* ── FAQ ── */
.lp-faq-item { border-bottom: 1.5px solid #bae6fd; }
.lp-faq-q {
  cursor: pointer; padding: 20px 4px;
  display: flex; justify-content: space-between; align-items: center;
  font-size: 15px; font-weight: 800; color: #0c1a2e; font-family: 'Nunito', sans-serif;
}
.lp-faq-q:hover { color: #0284c7; }
.lp-faq-icon { color: #7dd3fc; transition: transform .2s; font-size: 20px; }
.lp-faq-item.open .lp-faq-icon { transform: rotate(45deg); color: #0284c7; }
.lp-faq-a { display: none; padding: 0 4px 20px; font-size: 14px; color: #334155; line-height: 1.7; font-weight: 600; }
.lp-faq-item.open .lp-faq-a { display: block; }

/* ── Footer ── */
.lp-footer { background: #0c1a2e; color: rgba(255,255,255,.6); padding: 52px 5vw 28px; }
.lp-footer-grid { display:grid; grid-template-columns:2fr 1fr 1fr 1fr; gap:40px; margin-bottom:40px; }
.lp-footer-logo { font-size:20px; font-weight:900; color:#fff; margin-bottom:10px; font-family:'Nunito',sans-serif; }
.lp-footer-logo span { color: #38bdf8; }
.lp-footer-col h5 { font-size:12px; font-weight:900; color:rgba(255,255,255,.9); text-transform:uppercase; letter-spacing:1px; margin-bottom:14px; font-family:'Nunito',sans-serif; }
.lp-footer-col a { display:block; color:rgba(255,255,255,.55); text-decoration:none; margin-bottom:8px; transition:color .15s; font-weight:600; }
.lp-footer-col a:hover { color:#38bdf8; }

/* ── Star rating select ── */
.lp-star-select span { font-size:26px; cursor:pointer; color:#d1d5db; transition:color .1s; }
.lp-star-select span.active,.lp-star-select span:hover { color:#f59e0b; }

/* ── Theme button ── */
.theme-btn {
  display:flex; align-items:center; gap:6px; padding:7px 14px;
  border-radius:50px; font-size:12px; font-weight:800; cursor:pointer;
  border:2px solid #bae6fd; background:transparent; color:#0284c7;
  transition:all .15s; font-family:'Nunito',sans-serif;
}
.theme-btn:hover { border-color:#0284c7; background:#e0f2fe; }

/* ── Auth overlay ── */
.auth-card { background:#fff; border-radius:24px; padding:40px; }
.auth-logo { font-family:'Nunito',sans-serif; font-weight:900; }
.auth-tab  { font-family:'Nunito',sans-serif; font-weight:800; }
.lfg label { font-family:'Nunito',sans-serif; }

/* ── Dark mode ── */
body.lf-dark { --lp-bg:#0d1117; --lp-white:#161b22; --lp-text:#e6edf3; --lp-muted:#8b949e; --lp-subtle:#1c2b3a; --lp-border:#30363d; background:#0d1117; }
body.lf-dark .lp-nav { background:rgba(13,17,23,.97); border-bottom-color:#21395a; }
body.lf-dark .lp-hero-wrapper::before { background:linear-gradient(135deg,rgba(2,64,110,.92) 0%,rgba(3,105,161,.85) 50%,rgba(14,165,233,.7) 100%); }
body.lf-dark .lp-step  { background:#161b22; border-color:#21395a; }
body.lf-dark .lp-step h4 { color:#e6edf3; }
body.lf-dark .lp-step p  { color:#8b949e; }
body.lf-dark .lp-price-card { background:#161b22 !important; border-color:#21395a !important; }
body.lf-dark .lp-price-card.featured { background:#0d2137 !important; }
body.lf-dark .lp-price-card-name { color:#e6edf3 !important; }
body.lf-dark .lp-price-card-desc, body.lf-dark .lp-price-features li { color:#c9d1d9 !important; }
body.lf-dark .lp-review { background:#161b22; border-color:#21395a; }
body.lf-dark .lp-review-text { color:#c9d1d9; }
body.lf-dark .lp-faq-item { border-bottom-color:#21395a; }
body.lf-dark .lp-faq-q { color:#e6edf3; }
body.lf-dark .section-title, body.lf-dark .lp-section-title { color:#e6edf3; }
body.lf-dark .lp-hero-card { background:#1c2b3a !important; }
body.lf-dark .lp-hero-card-title { color:#e6edf3 !important; }
body.lf-dark .price-row-label { color:#e6edf3 !important; }
body.lf-dark .price-row-sub   { color:#8b949e !important; }
body.lf-dark .price-row       { border-bottom-color:#21395a !important; }
body.lf-dark .auth-card { background:#161b22; }
body.lf-dark .lfg input, body.lf-dark .lfg select { background:#0d1117; color:#e6edf3; border-color:#30363d; }
body.lf-dark .lp-rf-input { background:#0d1117; color:#e6edf3; border-color:#30363d; }
'''

# Insert before first </style>
style_end = content.find('</style>')
if style_end != -1:
    content = content[:style_end] + NEW_CSS + '\n' + content[style_end:]
    print("✓ Injected complete redesign CSS")

# ── Step 4: Fix hero HTML ─────────────────────────────────────────────────
# Make sure wrapper exists and has correct bubble divs + image
# First, fix the hero wrapper if it's missing
if 'class="lp-hero-wrapper"' not in content:
    # Wrap the hero
    old_h = '  <!-- HERO -->\n\n  <div class="lp-hero">'
    new_h = '  <!-- HERO -->\n\n  <div class="lp-hero-wrapper">\n    <div class="lp-bubble-deco"></div>\n    <div class="lp-bubble-deco"></div>\n    <div class="lp-bubble-deco"></div>\n    <div class="lp-bubble-deco"></div>\n  <div class="lp-hero">'
    content = content.replace(old_h, new_h, 1)
    # Close wrapper after hero
    content = content.replace('  </div>\n\n\n\n  <!-- HOW IT WORKS -->', '  </div>\n  </div><!-- /.lp-hero-wrapper -->\n\n\n\n  <!-- HOW IT WORKS -->', 1)
    print("✓ Added hero wrapper")
else:
    # Make sure bubbles are correct
    if 'lp-hero-bubbles' in content:
        content = content.replace(
            '<div class="lp-hero-bubbles"></div>',
            '<div class="lp-bubble-deco"></div>\n    <div class="lp-bubble-deco"></div>\n    <div class="lp-bubble-deco"></div>\n    <div class="lp-bubble-deco"></div>'
        )
    print("✓ Hero wrapper exists")

# ── Step 5: Fix step images — correct photos ─────────────────────────────
# Step 01 — person booking on phone
content = re.sub(
    r'(Step 01.*?lp-step-img.*?src=")[^"]*(")',
    r'\g<1>https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&auto=format&fit=crop&q=80\2',
    content, flags=re.DOTALL
)
# Step 03 — washing machine (not headset)
content = re.sub(
    r'(Step 03.*?lp-step-img.*?src=")[^"]*(")',
    r'\g<1>https://images.unsplash.com/photo-1521656693074-0ef32e80a5d5?w=400&auto=format&fit=crop&q=80\2',
    content, flags=re.DOTALL
)

print("✓ Fixed step images")

# ── Step 6: Fix hero note to use note-items ───────────────────────────────
old_note = '      <div class="lp-hero-note">✅ Walk-in welcome &nbsp;·&nbsp; 💳 GCash &amp; Cash &nbsp;·&nbsp; 📡 RFID-tracked</div>'
new_note = '''      <div class="lp-hero-note">
        <span class="lp-hero-note-item">✅ Walk-in welcome</span>
        <span class="lp-hero-note-item">💳 GCash &amp; Cash</span>
        <span class="lp-hero-note-item">📡 RFID-tracked</span>
      </div>'''
if old_note in content:
    content = content.replace(old_note, new_note)
    print("✓ Fixed hero note")

# ── Step 7: Fix the portal/app display issue ─────────────────────────────
# Ensure app and portal start as display:none in their inline styles
content = content.replace(
    '<div id="app">',
    '<div id="app" style="display:none;">',
    1
)
portal_tag = '<div id="portal">'
if portal_tag in content and 'id="portal" style' not in content:
    content = content.replace(portal_tag, '<div id="portal" style="display:none;">', 1)
print("✓ Fixed app/portal display:none")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ Full redesign complete!")
