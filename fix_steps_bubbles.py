path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

count = 0

# ══════════════════════════════════════════════════════════════════════
# FIX 1: Update step images to use the 4 uploaded photos
# ══════════════════════════════════════════════════════════════════════

# Step 01 — booking.jpg
content = re.sub(
    r"(<div class=\"lp-step\">\s*<img class=\"lp-step-img\"[^>]*step-01[^>]*>|"
    r"<div class=\"lp-step\">\s*<img class=\"lp-step-img\"[^>]*src=\"[^\"]*\"[^>]*>\s*<div class=\"lp-step-img-placeholder[^>]*>📱</div>\s*<div class=\"lp-step-body\">\s*<div class=\"lp-step-num\">01</div>)",
    lambda m: m.group(0),  # placeholder, handled below
    content
)

# Replace each step image src directly by looking for the step number in nearby context
def replace_step_img(content, step_num, new_src):
    """Replace the src of the lp-step-img that's followed by step number"""
    # Pattern: lp-step-img ... then within the same .lp-step block, find the step num
    pattern = re.compile(
        r'(<div class="lp-step">[\s\S]*?<img class="lp-step-img"[^>]*?)src="[^"]*"([^>]*>[\s\S]*?<div class="lp-step-num">' + str(step_num) + r'</div>)',
        re.DOTALL
    )
    new_content, n = pattern.subn(lambda m: m.group(1) + f'src="{new_src}"' + m.group(2), content)
    return new_content, n

content, n1 = replace_step_img(content, '01', 'booking.jpg')
content, n2 = replace_step_img(content, '02', 'rfid.jpg')
content, n3 = replace_step_img(content, '03', 'washing.jpg')
content, n4 = replace_step_img(content, '04', 'pick-up.jpg')

print(f"✓ Updated step images: step01={n1}, step02={n2}, step03={n3}, step04={n4}")
count += 4

# ══════════════════════════════════════════════════════════════════════
# FIX 2: Add bubble effects CSS to white section backgrounds
# ══════════════════════════════════════════════════════════════════════

BUBBLE_CSS = """

/* ════════════════════════════════════════════════════════════
   BUBBLE BACKGROUND EFFECTS — White sections get bubble SVGs
════════════════════════════════════════════════════════════ */

/* Reusable bubble pattern */
.lp-bubble-bg {
  position: relative; overflow: hidden;
}
.lp-bubble-bg::before {
  content: '';
  position: absolute; inset: 0; pointer-events: none; z-index: 0;
  background-image:
    radial-gradient(circle, rgba(14,165,233,.12) 1px, transparent 1px),
    radial-gradient(circle, rgba(56,189,248,.08) 1px, transparent 1px);
  background-size: 48px 48px, 24px 24px;
  background-position: 0 0, 12px 12px;
}

/* How It Works section */
#how {
  position: relative; overflow: hidden;
  background: linear-gradient(180deg, #f0f9ff 0%, #e8f5fe 100%);
}
#how::before {
  content: '';
  position: absolute; inset: 0; pointer-events: none; z-index: 0;
  background-image:
    radial-gradient(circle at 20% 30%, rgba(14,165,233,.10) 60px, transparent 60px),
    radial-gradient(circle at 80% 70%, rgba(56,189,248,.08) 90px, transparent 90px),
    radial-gradient(circle at 50% 90%, rgba(2,132,199,.07) 50px, transparent 50px),
    radial-gradient(circle at 10% 80%, rgba(125,211,252,.09) 40px, transparent 40px),
    radial-gradient(circle at 90% 20%, rgba(14,165,233,.06) 70px, transparent 70px);
}
#how .lp-section-title, #how .lp-eyebrow, #how .lp-section-sub { position: relative; z-index: 1; }
#how .lp-steps { position: relative; z-index: 1; }

/* Pricing section */
#pricing {
  position: relative; overflow: hidden;
  background: linear-gradient(180deg, #ffffff 0%, #f0f9ff 60%, #e0f2fe 100%);
}
#pricing::before {
  content: '';
  position: absolute; inset: 0; pointer-events: none; z-index: 0;
  background-image:
    radial-gradient(circle at 5% 20%,  rgba(14,165,233,.08) 80px, transparent 80px),
    radial-gradient(circle at 95% 80%, rgba(56,189,248,.07) 100px, transparent 100px),
    radial-gradient(circle at 40% 10%, rgba(2,132,199,.05) 60px, transparent 60px),
    radial-gradient(circle at 70% 90%, rgba(125,211,252,.08) 70px, transparent 70px);
}
#pricing > * { position: relative; z-index: 1; }

/* Reviews section */
#reviews {
  position: relative; overflow: hidden;
  background: linear-gradient(180deg, #f0f9ff 0%, #e8f5fe 100%) !important;
}
#reviews::before {
  content: '';
  position: absolute; inset: 0; pointer-events: none; z-index: 0;
  background-image:
    radial-gradient(circle at 15% 60%, rgba(14,165,233,.09) 55px, transparent 55px),
    radial-gradient(circle at 85% 30%, rgba(56,189,248,.07) 75px, transparent 75px),
    radial-gradient(circle at 50% 80%, rgba(2,132,199,.06) 45px, transparent 45px);
}
#reviews > * { position: relative; z-index: 1; }

/* FAQ section */
#faq {
  position: relative; overflow: hidden;
  background: #ffffff;
}
#faq::before {
  content: '';
  position: absolute; inset: 0; pointer-events: none; z-index: 0;
  background-image:
    radial-gradient(circle at 92% 15%, rgba(14,165,233,.07) 65px, transparent 65px),
    radial-gradient(circle at 8% 85%,  rgba(56,189,248,.06) 55px, transparent 55px),
    radial-gradient(circle at 50% 50%, rgba(2,132,199,.04) 90px, transparent 90px);
}
#faq .lp-section { position: relative; z-index: 1; }

/* Page body background — subtle bubble dots */
body { background: #f0f9ff; }
#landing {
  background: linear-gradient(180deg,
    #f0f9ff 0%,
    #ffffff 20%,
    #f0f9ff 50%,
    #ffffff 75%,
    #f0f9ff 100%
  );
}

/* Floating decorative bubbles — scattered on white sections */
.lp-deco-bubble {
  position: absolute; border-radius: 50%;
  background: radial-gradient(circle at 35% 35%, rgba(56,189,248,.25), rgba(14,165,233,.08));
  border: 1px solid rgba(56,189,248,.2);
  pointer-events: none; z-index: 0;
  animation: lf-float 10s ease-in-out infinite;
}

/* Bubbles in How It Works section */
#how .lp-deco-bubble:nth-child(1){ width:120px;height:120px; top:5%;  left:2%;   animation-duration:12s; }
#how .lp-deco-bubble:nth-child(2){ width:80px; height:80px;  bottom:8%;right:3%;  animation-duration:9s;  animation-delay:-3s; }
#how .lp-deco-bubble:nth-child(3){ width:55px; height:55px;  top:40%; left:95%;  animation-duration:11s; animation-delay:-6s; }

/* Bubbles in Pricing section */
#pricing .lp-deco-bubble:nth-child(1){ width:100px;height:100px; top:3%;   left:1%;   animation-duration:13s; }
#pricing .lp-deco-bubble:nth-child(2){ width:65px; height:65px;  bottom:5%;right:2%;  animation-duration:8s;  animation-delay:-4s; }

/* Bubbles in Reviews section */
#reviews .lp-deco-bubble:nth-child(1){ width:90px;height:90px; top:5%;   right:4%;  animation-duration:10s; }
#reviews .lp-deco-bubble:nth-child(2){ width:60px;height:60px; bottom:8%;left:3%;   animation-duration:7s;  animation-delay:-2s; }

/* Step card accent top border */
.lp-step::after {
  content: '';
  position: absolute; top: 0; left: 0; right: 0;
  height: 4px;
  background: linear-gradient(90deg, #0284c7, #38bdf8, #7dd3fc);
  opacity: 0;
  transition: opacity .3s;
}
.lp-step:hover::after { opacity: 1; }

/* Section separator wave */
.lp-wave-sep {
  width: 100%; overflow: hidden; line-height: 0;
  display: block; margin-top: -2px;
}
.lp-wave-sep svg { display: block; width: 100%; height: 60px; }
"""

# Inject before last </style>
style_end = content.rfind('</style>')
if style_end != -1:
    content = content[:style_end] + BUBBLE_CSS + '\n' + content[style_end:]
    count += 1
    print("✓ Injected bubble background CSS")

# ══════════════════════════════════════════════════════════════════════
# FIX 3: Add decorative bubble divs and wave separators to sections
# ══════════════════════════════════════════════════════════════════════

# Add bubble divs inside #how section
old_how = '  <div class="lp-section" id="how">\n\n    <div class="lp-eyebrow">Simple Process</div>'
new_how = '''  <div class="lp-section" id="how">
    <div class="lp-deco-bubble"></div>
    <div class="lp-deco-bubble"></div>
    <div class="lp-deco-bubble"></div>

    <div class="lp-eyebrow">Simple Process</div>'''
if old_how in content:
    content = content.replace(old_how, new_how)
    print("✓ Added bubbles to How It Works section")

# Add bubble divs inside pricing section
old_pricing = '  <div class="lp-section" id="pricing">\n\n    <div class="lp-eyebrow">Transparent Rates</div>'
new_pricing = '''  <div class="lp-section" id="pricing">
    <div class="lp-deco-bubble"></div>
    <div class="lp-deco-bubble"></div>

    <div class="lp-eyebrow">Transparent Rates</div>'''
if old_pricing in content:
    content = content.replace(old_pricing, new_pricing)
    print("✓ Added bubbles to Pricing section")

# Add wave separator after hero wrapper
old_after_hero = '  </div><!-- /.lp-hero-wrapper -->'
new_after_hero = '''  </div><!-- /.lp-hero-wrapper -->
  <!-- Wave separator -->
  <div class="lp-wave-sep">
    <svg viewBox="0 0 1440 60" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M0,30 C240,60 480,0 720,30 C960,60 1200,0 1440,30 L1440,60 L0,60 Z" fill="#f0f9ff"/>
    </svg>
  </div>'''
if old_after_hero in content:
    content = content.replace(old_after_hero, new_after_hero)
    print("✓ Added wave separator after hero")

# Add wave before services section
old_before_svc = '  <!-- SERVICES -->\n\n  <div class="lp-services-bg" id="services">'
new_before_svc = '''  <!-- SERVICES -->
  <div class="lp-wave-sep" style="background:#e8f5fe;margin-top:-2px;">
    <svg viewBox="0 0 1440 60" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M0,20 C360,55 720,0 1080,40 C1260,58 1380,10 1440,20 L1440,60 L0,60 Z" fill="#0c1a2e"/>
    </svg>
  </div>

  <div class="lp-services-bg" id="services">'''
if old_before_svc in content:
    content = content.replace(old_before_svc, new_before_svc)
    print("✓ Added wave before services")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"\n✅ Done! {count} changes applied")
