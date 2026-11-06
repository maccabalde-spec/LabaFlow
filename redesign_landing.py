"""
Full landing page redesign: sky blue / white / black bubble theme.
Changes ONLY CSS and HTML structure for the landing page.
Does NOT touch any JS functions.
"""
path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# ══════════════════════════════════════════════════════════════════════
# STEP 1: Update CSS variables and landing page styles
# ══════════════════════════════════════════════════════════════════════

OLD_VARS = """:root{

  /* Landing page palette — light/clean */

  --lp-bg:      #f8f9fa;

  --lp-white:   #ffffff;

  --lp-text:    #111827;

  --lp-muted:   #6b7280;

  --lp-subtle:  #f3f4f6;

  --lp-border:  #e5e7eb;

  --lp-accent:  #0284c7;

  --lp-accent2: #0369a1;

  --lp-navy:    #0a1628;"""

NEW_VARS = """:root{

  /* ── LabaFlow Landing – Sky Blue / White / Black Bubble Theme ── */
  --lp-bg:      #f0f8ff;      /* alice blue — fresh, airy */
  --lp-white:   #ffffff;
  --lp-text:    #0f172a;      /* near-black for high contrast */
  --lp-muted:   #475569;
  --lp-subtle:  #e0f2fe;      /* light sky tint */
  --lp-border:  #bae6fd;      /* sky blue border */
  --lp-accent:  #0ea5e9;      /* sky-500 — vibrant sky blue */
  --lp-accent2: #0284c7;      /* sky-600 — darker hover */
  --lp-accent3: #7dd3fc;      /* sky-300 — light highlight */
  --lp-navy:    #0c1a2e;      /* deep navy-black */
  --lp-bubble1: #e0f2fe;      /* bubble fill light */
  --lp-bubble2: #bae6fd;      /* bubble fill medium */"""

if OLD_VARS in content:
    content = content.replace(OLD_VARS, NEW_VARS)
    print("✓ Updated CSS variables")

# ══════════════════════════════════════════════════════════════════════
# STEP 2: Replace entire landing page CSS block
# ══════════════════════════════════════════════════════════════════════

OLD_NAV_CSS = """.lp-nav{position:sticky;top:0;z-index:100;background:rgba(255,255,255,.97);backdrop-filter:blur(8px);border-bottom:1px solid var(--lp-border);padding:0 5vw;height:64px;display:flex;align-items:center;justify-content:space-between;}
.lp-nav-logo{font-size:20px;font-weight:800;color:var(--lp-text);letter-spacing:-.5px;text-decoration:none;}
.lp-nav-logo span{color:var(--lp-accent);}
.lp-nav-links{display:flex;align-items:center;gap:28px;}
.lp-nav-links a{font-size:13px;font-weight:500;color:var(--lp-muted);text-decoration:none;transition:color .15s;}
.lp-nav-links a:hover{color:var(--lp-text);}
.lp-nav-cta{display:flex;gap:10px;align-items:center;}
.lp-btn{display:inline-flex;align-items:center;gap:6px;padding:9px 20px;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;transition:all .15s;text-decoration:none;border:none;}
.lp-btn-outline{background:transparent;color:var(--lp-text);border:1.5px solid var(--lp-border);}
.lp-btn-outline:hover{border-color:var(--lp-accent);color:var(--lp-accent);}
.lp-btn-solid{background:var(--lp-accent);color:#fff;}
.lp-btn-solid:hover{background:var(--lp-accent2);}
.lp-btn-lg{padding:14px 32px;font-size:15px;border-radius:10px;}
.lp-btn-dark{background:var(--lp-navy);color:#fff;}
.lp-btn-dark:hover{background:#162040;}"""

NEW_NAV_CSS = """.lp-nav{
  position:sticky;top:0;z-index:100;
  background:rgba(255,255,255,.95);
  backdrop-filter:blur(12px);
  -webkit-backdrop-filter:blur(12px);
  border-bottom:1px solid rgba(14,165,233,.15);
  padding:0 5vw;height:68px;
  display:flex;align-items:center;justify-content:space-between;
  box-shadow:0 2px 20px rgba(14,165,233,.08);
}
.lp-nav-logo{
  font-size:22px;font-weight:900;
  color:var(--lp-text);letter-spacing:-.8px;text-decoration:none;
  display:flex;align-items:center;gap:8px;
}
.lp-nav-logo::before{
  content:'🫧';font-size:20px;
}
.lp-nav-logo span{color:var(--lp-accent);}
.lp-nav-links{display:flex;align-items:center;gap:32px;}
.lp-nav-links a{
  font-size:13px;font-weight:600;color:var(--lp-muted);
  text-decoration:none;transition:all .2s;
  position:relative;padding-bottom:2px;
}
.lp-nav-links a::after{
  content:'';position:absolute;bottom:-2px;left:0;right:0;
  height:2px;background:var(--lp-accent);border-radius:2px;
  transform:scaleX(0);transition:transform .2s;
}
.lp-nav-links a:hover{color:var(--lp-accent);}
.lp-nav-links a:hover::after{transform:scaleX(1);}
.lp-nav-cta{display:flex;gap:10px;align-items:center;}
.lp-btn{
  display:inline-flex;align-items:center;gap:6px;
  padding:9px 22px;border-radius:50px;
  font-size:13px;font-weight:700;cursor:pointer;
  transition:all .2s;text-decoration:none;border:none;
  letter-spacing:.1px;
}
.lp-btn-outline{
  background:transparent;color:var(--lp-accent);
  border:2px solid var(--lp-accent);
}
.lp-btn-outline:hover{
  background:var(--lp-accent);color:#fff;
  transform:translateY(-1px);
  box-shadow:0 4px 16px rgba(14,165,233,.3);
}
.lp-btn-solid{
  background:linear-gradient(135deg,var(--lp-accent),var(--lp-accent2));
  color:#fff;
  box-shadow:0 4px 16px rgba(14,165,233,.3);
}
.lp-btn-solid:hover{
  background:linear-gradient(135deg,#0ea5e9,#0369a1);
  transform:translateY(-2px);
  box-shadow:0 8px 24px rgba(14,165,233,.4);
}
.lp-btn-lg{padding:15px 36px;font-size:15px;}
.lp-btn-dark{
  background:var(--lp-navy);color:#fff;
  box-shadow:0 4px 16px rgba(0,0,0,.2);
}
.lp-btn-dark:hover{background:#1e3a5f;transform:translateY(-2px);}"""

if OLD_NAV_CSS in content:
    content = content.replace(OLD_NAV_CSS, NEW_NAV_CSS)
    print("✓ Updated navbar CSS")

# ══════════════════════════════════════════════════════════════════════
# STEP 3: Hero section — add background wrapper, background image
# ══════════════════════════════════════════════════════════════════════

OLD_HERO_CSS = """.lp-hero{padding:90px 5vw 80px;display:flex;align-items:center;justify-content:space-between;gap:40px;max-width:1200px;margin:0 auto;}
.lp-hero-left{flex:1;max-width:580px;}
.lp-hero-eyebrow{display:inline-flex;align-items:center;gap:7px;background:#e0f2fe;color:var(--lp-accent);font-size:12px;font-weight:700;padding:5px 12px;border-radius:20px;margin-bottom:20px;letter-spacing:.3px;text-transform:uppercase;}
.lp-hero-eyebrow span{width:6px;height:6px;background:var(--lp-accent);border-radius:50%;display:inline-block;}
.lp-hero h1{font-size:clamp(36px,4.5vw,58px);font-weight:800;line-height:1.08;letter-spacing:-1.5px;color:var(--lp-text);margin-bottom:20px;}
.lp-hero h1 em{font-style:normal;color:var(--lp-accent);}
.lp-hero p{font-size:17px;color:var(--lp-muted);line-height:1.65;margin-bottom:32px;max-width:480px;}
.lp-hero-actions{display:flex;gap:12px;flex-wrap:wrap;align-items:center;}
.lp-hero-note{font-size:12px;color:var(--lp-muted);margin-top:16px;}
.lp-hero-right{flex:0 0 420px;max-width:420px;}"""

NEW_HERO_CSS = """.lp-hero-wrapper{
  position:relative;
  overflow:hidden;
  background:linear-gradient(160deg,#0ea5e9 0%,#38bdf8 35%,#f0f9ff 70%,#ffffff 100%);
  min-height:600px;
}
.lp-hero-bg-img{
  position:absolute;bottom:0;left:0;right:0;
  width:100%;height:70%;
  object-fit:cover;object-position:bottom center;
  opacity:0.18;
  pointer-events:none;
  mix-blend-mode:multiply;
}
.lp-hero-bubbles{
  position:absolute;inset:0;pointer-events:none;overflow:hidden;
}
.lp-hero-bubbles::before,.lp-hero-bubbles::after{
  content:'';position:absolute;border-radius:50%;
  background:rgba(255,255,255,.15);
  animation:float 8s ease-in-out infinite;
}
.lp-hero-bubbles::before{width:300px;height:300px;top:-80px;right:15%;animation-delay:-2s;}
.lp-hero-bubbles::after{width:200px;height:200px;bottom:10%;left:5%;animation-delay:-4s;}
@keyframes float{
  0%,100%{transform:translateY(0) scale(1);}
  50%{transform:translateY(-20px) scale(1.05);}
}
.lp-hero{
  padding:90px 5vw 80px;
  display:flex;align-items:center;justify-content:space-between;
  gap:40px;max-width:1200px;margin:0 auto;
  position:relative;z-index:1;
}
.lp-hero-left{flex:1;max-width:580px;}
.lp-hero-eyebrow{
  display:inline-flex;align-items:center;gap:7px;
  background:rgba(255,255,255,.9);
  color:var(--lp-accent2);
  font-size:12px;font-weight:800;
  padding:6px 14px;border-radius:50px;
  margin-bottom:20px;letter-spacing:.5px;text-transform:uppercase;
  border:1px solid rgba(14,165,233,.3);
  backdrop-filter:blur(4px);
  box-shadow:0 2px 8px rgba(14,165,233,.15);
}
.lp-hero-eyebrow span{width:7px;height:7px;background:var(--lp-accent);border-radius:50%;display:inline-block;box-shadow:0 0 6px rgba(14,165,233,.6);}
.lp-hero h1{
  font-size:clamp(38px,5vw,64px);font-weight:900;
  line-height:1.05;letter-spacing:-2px;
  color:#fff;margin-bottom:20px;
  text-shadow:0 2px 20px rgba(2,132,199,.3);
}
.lp-hero h1 em{font-style:normal;color:#fff;position:relative;}
.lp-hero h1 em::after{
  content:'';position:absolute;bottom:-4px;left:0;right:0;
  height:4px;background:rgba(255,255,255,.6);border-radius:2px;
}
.lp-hero p{
  font-size:17px;color:rgba(255,255,255,.9);
  line-height:1.7;margin-bottom:32px;max-width:480px;
  text-shadow:0 1px 4px rgba(0,0,0,.1);
}
.lp-hero-actions{display:flex;gap:12px;flex-wrap:wrap;align-items:center;}
.lp-hero-note{
  font-size:12px;color:rgba(255,255,255,.85);margin-top:20px;
  display:flex;gap:16px;flex-wrap:wrap;
}
.lp-hero-note-item{
  display:flex;align-items:center;gap:5px;
  background:rgba(255,255,255,.2);
  padding:4px 10px;border-radius:20px;
  backdrop-filter:blur(4px);
  border:1px solid rgba(255,255,255,.3);
}
.lp-hero-right{flex:0 0 420px;max-width:420px;}"""

if OLD_HERO_CSS in content:
    content = content.replace(OLD_HERO_CSS, NEW_HERO_CSS)
    print("✓ Updated hero CSS")

# ══════════════════════════════════════════════════════════════════════
# STEP 4: Update hero card CSS
# ══════════════════════════════════════════════════════════════════════
old_card = """.lp-hero-card{background:var(--lp-white);border-radius:20px;padding:28px;box-shadow:0 8px 40px rgba(0,0,0,.1);border:1px solid var(--lp-border);color:var(--lp-text);}
.lp-hero-card-title{font-size:14px;font-weight:700;color:var(--lp-text) !important;margin-bottom:16px;}"""

new_card = """.lp-hero-card{
  background:rgba(255,255,255,.95);
  border-radius:24px;padding:28px;
  box-shadow:0 20px 60px rgba(2,132,199,.25),0 4px 16px rgba(0,0,0,.08);
  border:1px solid rgba(255,255,255,.8);
  backdrop-filter:blur(16px);
  -webkit-backdrop-filter:blur(16px);
}
.lp-hero-card-title{
  font-size:14px;font-weight:800;color:var(--lp-text) !important;
  margin-bottom:16px;display:flex;align-items:center;gap:8px;
  padding-bottom:12px;border-bottom:2px solid var(--lp-subtle);
}"""
if old_card in content:
    content = content.replace(old_card, new_card)
    print("✓ Updated hero card CSS")

# ══════════════════════════════════════════════════════════════════════
# STEP 5: Steps section — bubble-themed cards with images
# ══════════════════════════════════════════════════════════════════════
old_steps = """.lp-steps{display:grid;grid-template-columns:repeat(4,1fr);gap:24px;margin-top:48px;}
.lp-step{background:var(--lp-white);border-radius:16px;padding:28px 24px;border:1px solid var(--lp-border);position:relative;transition:transform .2s,box-shadow .2s;}
.lp-step:hover{transform:translateY(-4px);box-shadow:0 12px 36px rgba(0,0,0,.08);}
.lp-step-num{font-size:11px;font-weight:800;color:var(--lp-accent);letter-spacing:.5px;margin-bottom:14px;text-transform:uppercase;}
.lp-step-icon{font-size:32px;margin-bottom:14px;display:block;}
.lp-step h4{font-size:15px;font-weight:700;color:var(--lp-text);margin-bottom:8px;}
.lp-step p{font-size:13px;color:var(--lp-muted);line-height:1.55;}"""

new_steps = """.lp-steps{display:grid;grid-template-columns:repeat(4,1fr);gap:24px;margin-top:48px;}
.lp-step{
  background:var(--lp-white);
  border-radius:24px;
  overflow:hidden;
  border:1.5px solid var(--lp-bubble2);
  position:relative;
  transition:all .3s ease;
  box-shadow:0 4px 20px rgba(14,165,233,.08);
}
.lp-step:hover{
  transform:translateY(-6px);
  box-shadow:0 16px 48px rgba(14,165,233,.2);
  border-color:var(--lp-accent);
}
.lp-step-img{
  width:100%;height:160px;
  object-fit:cover;
  display:block;
  background:linear-gradient(135deg,#e0f2fe,#bae6fd);
}
.lp-step-img-placeholder{
  width:100%;height:160px;
  display:flex;align-items:center;justify-content:center;
  background:linear-gradient(135deg,var(--lp-subtle),var(--lp-bubble2));
  font-size:60px;
}
.lp-step-body{padding:20px 20px 24px;}
.lp-step-num{
  display:inline-flex;align-items:center;justify-content:center;
  width:28px;height:28px;border-radius:50%;
  background:var(--lp-accent);color:#fff;
  font-size:11px;font-weight:800;margin-bottom:12px;
  box-shadow:0 2px 8px rgba(14,165,233,.4);
}
.lp-step-icon{font-size:28px;margin-bottom:8px;display:block;}
.lp-step h4{font-size:15px;font-weight:800;color:var(--lp-text);margin-bottom:6px;}
.lp-step p{font-size:13px;color:var(--lp-muted);line-height:1.6;}"""
if old_steps in content:
    content = content.replace(old_steps, new_steps)
    print("✓ Updated steps CSS")

# ══════════════════════════════════════════════════════════════════════
# STEP 6: Services section — brighter, sky blue feel
# ══════════════════════════════════════════════════════════════════════
old_svc_bg = """.lp-services-bg{background:var(--lp-navy);}
.lp-services-inner{padding:80px 5vw;max-width:1200px;margin:0 auto;}
.lp-services-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-top:48px;}
.lp-svc{background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);border-radius:16px;padding:28px 24px;transition:all .2s;}
.lp-svc:hover{background:rgba(255,255,255,.09);border-color:rgba(125,211,252,.25);}
.lp-svc-icon{font-size:30px;margin-bottom:14px;display:block;}
.lp-svc h4{font-size:15px;font-weight:700;color:#fff;margin-bottom:8px;}
.lp-svc p{font-size:13px;color:rgba(255,255,255,.6);line-height:1.55;}
.lp-svc-badge{display:inline-block;margin-top:12px;padding:3px 10px;background:rgba(125,211,252,.15);color:#7dd3fc;border-radius:20px;font-size:11px;font-weight:600;}"""

new_svc_bg = """.lp-services-bg{
  background:linear-gradient(160deg,#0c1a2e 0%,#0ea5e9 60%,#38bdf8 100%);
  position:relative;overflow:hidden;
}
.lp-services-bg::before{
  content:'';position:absolute;inset:0;
  background:url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Ccircle cx='30' cy='30' r='28' fill='none' stroke='rgba(255,255,255,0.04)' stroke-width='1'/%3E%3C/svg%3E") repeat;
  pointer-events:none;
}
.lp-services-inner{padding:80px 5vw;max-width:1200px;margin:0 auto;position:relative;}
.lp-services-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-top:48px;}
.lp-svc{
  background:rgba(255,255,255,.08);
  border:1px solid rgba(255,255,255,.15);
  border-radius:20px;padding:28px 24px;transition:all .3s;
  backdrop-filter:blur(8px);
}
.lp-svc:hover{
  background:rgba(255,255,255,.15);
  border-color:rgba(255,255,255,.4);
  transform:translateY(-4px);
  box-shadow:0 12px 32px rgba(0,0,0,.2);
}
.lp-svc-icon{
  font-size:36px;margin-bottom:14px;display:block;
  width:56px;height:56px;border-radius:16px;
  background:rgba(255,255,255,.15);
  display:flex;align-items:center;justify-content:center;
  backdrop-filter:blur(4px);
}
.lp-svc h4{font-size:16px;font-weight:800;color:#fff;margin-bottom:8px;}
.lp-svc p{font-size:13px;color:rgba(255,255,255,.75);line-height:1.6;}
.lp-svc-badge{
  display:inline-block;margin-top:12px;padding:4px 12px;
  background:rgba(255,255,255,.2);color:#fff;
  border-radius:50px;font-size:11px;font-weight:700;
  border:1px solid rgba(255,255,255,.3);
  backdrop-filter:blur(4px);
}"""
if old_svc_bg in content:
    content = content.replace(old_svc_bg, new_svc_bg)
    print("✓ Updated services CSS")

# ══════════════════════════════════════════════════════════════════════
# STEP 7: Pricing cards
# ══════════════════════════════════════════════════════════════════════
old_pricing = """.lp-pricing-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-top:48px;}
.lp-price-card{background:var(--lp-white);border:2px solid var(--lp-border);border-radius:20px;padding:32px 28px;transition:border-color .2s;}
.lp-price-card.featured{border-color:var(--lp-accent);box-shadow:0 8px 32px rgba(2,132,199,.12);}"""

new_pricing = """.lp-pricing-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;margin-top:48px;}
.lp-price-card{
  background:var(--lp-white);
  border:2px solid var(--lp-bubble2);
  border-radius:24px;padding:32px 28px;
  transition:all .3s;
  box-shadow:0 4px 20px rgba(14,165,233,.06);
}
.lp-price-card:hover{
  border-color:var(--lp-accent);
  transform:translateY(-4px);
  box-shadow:0 12px 40px rgba(14,165,233,.15);
}
.lp-price-card.featured{
  border-color:var(--lp-accent);
  box-shadow:0 12px 48px rgba(14,165,233,.25);
  background:linear-gradient(160deg,#f0f9ff 0%,#e0f2fe 100%);
  transform:scale(1.03);
}"""
if old_pricing in content:
    content = content.replace(old_pricing, new_pricing)
    print("✓ Updated pricing CSS")

# ══════════════════════════════════════════════════════════════════════
# STEP 8: CTA banner
# ══════════════════════════════════════════════════════════════════════
old_cta = """.lp-cta-bg{background:var(--lp-accent);padding:72px 5vw;text-align:center;}
.lp-cta-bg h2{font-size:clamp(26px,3vw,40px);font-weight:800;color:#fff;letter-spacing:-.5px;margin-bottom:12px;}
.lp-cta-bg p{font-size:16px;color:rgba(255,255,255,.85);margin-bottom:28px;}
.lp-btn-white{background:#fff;color:var(--lp-accent);font-weight:700;}
.lp-btn-white:hover{background:#f0f9ff;color:var(--lp-accent2);}"""

new_cta = """.lp-cta-bg{
  background:linear-gradient(135deg,#0c1a2e 0%,#0369a1 50%,#0ea5e9 100%);
  padding:80px 5vw;text-align:center;position:relative;overflow:hidden;
}
.lp-cta-bg::before{
  content:'🫧';font-size:200px;position:absolute;
  top:-40px;right:-20px;opacity:.06;pointer-events:none;
  transform:rotate(-15deg);
}
.lp-cta-bg::after{
  content:'🫧';font-size:160px;position:absolute;
  bottom:-30px;left:-10px;opacity:.05;pointer-events:none;
  transform:rotate(10deg);
}
.lp-cta-bg h2{font-size:clamp(28px,3.5vw,44px);font-weight:900;color:#fff;letter-spacing:-.8px;margin-bottom:14px;position:relative;}
.lp-cta-bg p{font-size:16px;color:rgba(255,255,255,.85);margin-bottom:32px;position:relative;}
.lp-btn-white{
  background:#fff;color:var(--lp-accent2);font-weight:800;
  box-shadow:0 8px 32px rgba(0,0,0,.2);position:relative;
}
.lp-btn-white:hover{
  background:#f0f9ff;color:var(--lp-accent);
  transform:translateY(-2px);box-shadow:0 12px 40px rgba(0,0,0,.3);
}"""
if old_cta in content:
    content = content.replace(old_cta, new_cta)
    print("✓ Updated CTA CSS")

# ══════════════════════════════════════════════════════════════════════
# STEP 9: Reviews and dark mode
# ══════════════════════════════════════════════════════════════════════
old_review = """.lp-reviews-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-top:48px;}
.lp-review{background:var(--lp-white);border:1px solid var(--lp-border);border-radius:16px;padding:26px 24px;}"""

new_review = """.lp-reviews-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-top:48px;}
.lp-review{
  background:var(--lp-white);
  border:1.5px solid var(--lp-bubble2);
  border-radius:20px;padding:26px 24px;
  transition:all .2s;
  box-shadow:0 2px 12px rgba(14,165,233,.06);
}
.lp-review:hover{
  border-color:var(--lp-accent);
  transform:translateY(-3px);
  box-shadow:0 8px 24px rgba(14,165,233,.12);
}"""
if old_review in content:
    content = content.replace(old_review, new_review)
    print("✓ Updated reviews CSS")

# ══════════════════════════════════════════════════════════════════════
# STEP 10: Section styles
# ══════════════════════════════════════════════════════════════════════
old_section = """.lp-section{padding:80px 5vw;max-width:1200px;margin:0 auto;}"""
new_section = """.lp-section{padding:90px 5vw;max-width:1200px;margin:0 auto;}"""
content = content.replace(old_section, new_section, 1)

old_eyebrow = """.lp-eyebrow{font-size:12px;font-weight:700;color:var(--lp-accent);text-transform:uppercase;letter-spacing:.8px;margin-bottom:10px;}"""
new_eyebrow = """.lp-eyebrow{
  font-size:12px;font-weight:800;color:var(--lp-accent);
  text-transform:uppercase;letter-spacing:1.2px;margin-bottom:10px;
  display:inline-flex;align-items:center;gap:6px;
}
.lp-eyebrow::before{content:'';width:20px;height:2px;background:var(--lp-accent);border-radius:1px;}"""
content = content.replace(old_eyebrow, new_eyebrow, 1)

old_title = """.lp-section-title{font-size:clamp(28px,3vw,40px);font-weight:800;letter-spacing:-.8px;color:var(--lp-text);margin-bottom:12px;}"""
new_title = """.lp-section-title{font-size:clamp(30px,3.5vw,44px);font-weight:900;letter-spacing:-1.2px;color:var(--lp-text);margin-bottom:14px;line-height:1.1;}"""
content = content.replace(old_title, new_title, 1)

print("✓ Updated section styles")

# ══════════════════════════════════════════════════════════════════════
# STEP 11: Wrap hero section in hero-wrapper div + add hero note items
# ══════════════════════════════════════════════════════════════════════

old_hero_html = """  <!-- HERO -->

  <div class="lp-hero">

    <div class="lp-hero-left">

      <div class="lp-hero-eyebrow"><span></span>Lab-a-Day Laundry Shop</div>

      <h1>Fresh Laundry,<br><em>Zero Hassle.</em></h1>

      <p>Drop off your clothes and we'll handle everything — wash, dry, fold, and have it ready for pickup. RFID-tracked orders so you always know where your laundry is.</p>

      <div class="lp-hero-actions">

        <button class="lp-btn lp-btn-solid lp-btn-lg" onclick="openAuth('reg')">Book a Service</button>

        <button class="lp-btn lp-btn-outline lp-btn-lg" onclick="document.getElementById('how').scrollIntoView({behavior:'smooth'})">How It Works</button>

      </div>

      <div class="lp-hero-note">✅ Walk-in welcome &nbsp;·&nbsp; 💳 GCash & Cash accepted &nbsp;·&nbsp; 📡 RFID-tracked</div>

    </div>"""

new_hero_html = """  <!-- HERO -->

  <div class="lp-hero-wrapper">
    <div class="lp-hero-bubbles"></div>
    <!-- Background image (laundry themed) -->
    <img class="lp-hero-bg-img"
      src="https://images.unsplash.com/photo-1521656693074-0ef32e80a5d5?w=1600&auto=format&fit=crop&q=60&ixlib=rb-4.0.3"
      alt="laundry background"
      onerror="this.style.display='none'"
    >

  <div class="lp-hero">

    <div class="lp-hero-left">

      <div class="lp-hero-eyebrow"><span></span>Lab-a-Day Laundry Shop</div>

      <h1>Fresh Laundry,<br><em>Zero Hassle.</em></h1>

      <p>Drop off your clothes and we'll handle everything — wash, dry, fold, and have it ready for pickup. RFID-tracked orders so you always know where your laundry is.</p>

      <div class="lp-hero-actions">

        <button class="lp-btn lp-btn-solid lp-btn-lg" style="background:#fff;color:var(--lp-accent);box-shadow:0 8px 32px rgba(0,0,0,.2);" onclick="openAuth('reg')">🧺 Book a Service</button>

        <button class="lp-btn lp-btn-outline lp-btn-lg" style="border-color:rgba(255,255,255,.6);color:#fff;" onclick="document.getElementById('how').scrollIntoView({behavior:'smooth'})">How It Works ↓</button>

      </div>

      <div class="lp-hero-note">
        <span class="lp-hero-note-item">✅ Walk-in welcome</span>
        <span class="lp-hero-note-item">💳 GCash & Cash</span>
        <span class="lp-hero-note-item">📡 RFID-tracked</span>
      </div>

    </div>"""

if old_hero_html in content:
    content = content.replace(old_hero_html, new_hero_html)
    print("✓ Updated hero HTML with wrapper + background")

# Close the wrapper after hero section
old_after_hero = """  </div>



  <!-- HOW IT WORKS -->"""

new_after_hero = """  </div>
  </div><!-- /.lp-hero-wrapper -->



  <!-- HOW IT WORKS -->"""

if old_after_hero in content:
    content = content.replace(old_after_hero, new_after_hero)
    print("✓ Closed hero wrapper")

# ══════════════════════════════════════════════════════════════════════
# STEP 12: Steps HTML — add AI images for each step
# ══════════════════════════════════════════════════════════════════════

step_replacements = [
    # Step 01 - Book / Walk In
    (
        '      <div class="lp-step">\n\n        <div class="lp-step-num">Step 01</div>\n\n        <span class="lp-step-icon">📋</span>\n\n        <h4>Book or Walk In</h4>\n\n        <p>Register online and book a service, or simply walk into our shop. Staff will create your order in seconds.</p>\n\n      </div>',
        '''      <div class="lp-step">
        <img class="lp-step-img" loading="lazy"
          src="https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=400&auto=format&fit=crop&q=70"
          alt="Book laundry service online"
          onerror="this.style.display='none';this.nextElementSibling.style.display='flex';"
        >
        <div class="lp-step-img-placeholder" style="display:none;">📱</div>
        <div class="lp-step-body">
          <div class="lp-step-num">01</div>
          <span class="lp-step-icon">📋</span>
          <h4>Book or Walk In</h4>
          <p>Register online and book a service, or simply walk into our shop. Staff will create your order in seconds.</p>
        </div>
      </div>'''
    ),
    # Step 02 - RFID
    (
        '      <div class="lp-step">\n\n        <div class="lp-step-num">Step 02</div>\n\n        <span class="lp-step-icon">📡</span>\n\n        <h4>RFID Tag Assigned</h4>\n\n        <p>Your laundry gets a unique RFID tag. We scan it to receive your items — your order is now tracked in real-time.</p>\n\n      </div>',
        '''      <div class="lp-step">
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
    ),
    # Step 03 - Wash & Dry
    (
        '      <div class="lp-step">\n\n        <div class="lp-step-num">Step 03</div>\n\n        <span class="lp-step-icon">🫧</span>\n\n        <h4>We Wash &amp; Dry</h4>\n\n        <p>Using Surf detergent, Surf conditioner, and Zonrox bleach, your laundry is washed and dried with care.</p>\n\n      </div>',
        '''      <div class="lp-step">
        <img class="lp-step-img" loading="lazy"
          src="https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&auto=format&fit=crop&q=70"
          alt="Washing machine laundry"
          onerror="this.style.display='none';this.nextElementSibling.style.display='flex';"
        >
        <div class="lp-step-img-placeholder" style="display:none;">🫧</div>
        <div class="lp-step-body">
          <div class="lp-step-num">03</div>
          <span class="lp-step-icon">🫧</span>
          <h4>We Wash &amp; Dry</h4>
          <p>Using Surf detergent, Surf conditioner, and Zonrox bleach, your laundry is washed and dried with care.</p>
        </div>
      </div>'''
    ),
    # Step 04 - Pickup
    (
        '      <div class="lp-step">\n\n        <div class="lp-step-num">Step 04</div>\n\n        <span class="lp-step-icon">✅</span>\n\n        <h4>Ready for Pickup</h4>\n\n        <p>You\'ll be notified when your laundry is ready. Pick up and pay — or earn loyalty points with every order!</p>\n\n      </div>',
        '''      <div class="lp-step">
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
      </div>'''
    ),
]

for old_s, new_s in step_replacements:
    if old_s in content:
        content = content.replace(old_s, new_s)
        print(f"✓ Updated step card")

# ══════════════════════════════════════════════════════════════════════
# STEP 13: Update lp-price-features checkmark
# ══════════════════════════════════════════════════════════════════════
old_feat = ".lp-price-features li::before{content:'₱';color:var(--lp-accent);font-weight:700;flex-shrink:0;}"
new_feat = ".lp-price-features li::before{content:'✓';color:var(--lp-accent);font-weight:800;flex-shrink:0;font-size:13px;}"
content = content.replace(old_feat, new_feat)
print("✓ Updated pricing features checkmark")

# ══════════════════════════════════════════════════════════════════════
# STEP 14: Add bubble animation keyframe and body styles
# ══════════════════════════════════════════════════════════════════════
import re

old_body = "body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;background:var(--lp-bg);color:var(--lp-text);font-size:14px;}"
new_body = """body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;background:var(--lp-bg);color:var(--lp-text);font-size:14px;}

/* ── Bubble float animations ── */
@keyframes bubbleFloat{
  0%,100%{transform:translateY(0) scale(1);opacity:.6;}
  50%{transform:translateY(-30px) scale(1.1);opacity:.9;}
}
@keyframes bubbleFade{
  0%{transform:scale(0);opacity:0;}
  50%{opacity:.5;}
  100%{transform:scale(1.5);opacity:0;}
}"""
content = content.replace(old_body, new_body)
print("✓ Added body styles + keyframes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ Redesign complete!")
