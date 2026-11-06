path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the previous broad CSS block that's causing issues
# It was added just before </style>
marker = '/* ════════════════════════════════════════\n   TEXT COLOR SYSTEM'
end_marker = '/* ── LIGHT MODE (default) — dark text on light bg ──'

# Find and remove from marker to the end of the block
idx_start = content.find(marker)
if idx_start == -1:
    # Try alternate
    idx_start = content.find('/* ════════════════════════════════════════\n   TEXT COLOR SYSTEM')
    
print(f"Found old CSS block at: {idx_start}")

if idx_start != -1:
    # Find the closing of this block - look for next section or </style>
    style_close = content.find('</style>', idx_start)
    content = content[:idx_start] + content[style_close:]
    print("✓ Removed old TEXT COLOR SYSTEM block")

# Now insert a TARGETED CSS fix - only fix what's actually broken
# The issue: broad h4/p rules override intentional white text on dark sections
style_close = content.find('</style>')

TARGETED_CSS = """
/* ════════════════════════════════════════
   TEXT CONTRAST FIX
   Target only the sections/elements that
   need color adjustment per mode.
   Does NOT override dark section white text.
════════════════════════════════════════ */

/* == LIGHT MODE FIXES == */
/* Step cards (white bg) — text must be dark */
body:not(.lf-dark) .lp-step-body h4,
body:not(.lf-dark) .lp-step h4 { color: #111827 !important; }
body:not(.lf-dark) .lp-step-body p,
body:not(.lf-dark) .lp-step p   { color: #374151 !important; }
body:not(.lf-dark) .lp-step-num { background: #0284c7 !important; color: #fff !important; }

/* Pricing cards (white bg) */
body:not(.lf-dark) .lp-price-card-label   { color: #6b7280 !important; }
body:not(.lf-dark) .lp-price-card-name    { color: #111827 !important; }
body:not(.lf-dark) .lp-price-card-price   { color: #0284c7 !important; }
body:not(.lf-dark) .lp-price-card-desc    { color: #374151 !important; }
body:not(.lf-dark) .lp-price-features li  { color: #111827 !important; }

/* Section headings (on light bg) */
body:not(.lf-dark) .lp-section-title { color: #111827 !important; }
body:not(.lf-dark) .lp-section-sub   { color: #374151 !important; }

/* Reviews (white bg) */
body:not(.lf-dark) .lp-review        { background: #fff; }
body:not(.lf-dark) .lp-review-text   { color: #111827 !important; }
body:not(.lf-dark) .lp-review-name   { color: #111827 !important; }

/* FAQ (white/light bg) */
body:not(.lf-dark) .lp-faq-q { color: #111827 !important; }
body:not(.lf-dark) .lp-faq-a { color: #374151 !important; }

/* Auth modal (white bg) */
body:not(.lf-dark) .auth-card    { background: #fff; color: #111827; }
body:not(.lf-dark) .auth-logo    { color: #111827; }
body:not(.lf-dark) .lfg label    { color: #374151; }


/* == DARK MODE FIXES == */
/* Step cards (light bg in dark mode) */
body.lf-dark .lp-step         { background: #161b22 !important; border-color: #30363d !important; }
body.lf-dark .lp-step-body    { background: #161b22 !important; }
body.lf-dark .lp-step h4      { color: #ffffff !important; }
body.lf-dark .lp-step p       { color: #c9d1d9 !important; }
body.lf-dark .lp-step-num     { color: #58a6ff !important; background: rgba(88,166,255,.2) !important; }

/* Pricing cards */
body.lf-dark .lp-price-card          { background: #161b22 !important; border-color: #30363d !important; }
body.lf-dark .lp-price-card.featured { background: #0d2137 !important; border-color: #388bfd !important; }
body.lf-dark .lp-price-card-label    { color: #8b949e !important; }
body.lf-dark .lp-price-card-name     { color: #ffffff !important; }
body.lf-dark .lp-price-card-price    { color: #58a6ff !important; }
body.lf-dark .lp-price-card-desc     { color: #c9d1d9 !important; }
body.lf-dark .lp-price-features li   { color: #c9d1d9 !important; border-bottom-color: #30363d !important; }

/* Section headings */
body.lf-dark .lp-section-title { color: #ffffff !important; }
body.lf-dark .lp-section-sub   { color: #c9d1d9 !important; }

/* Services section (dark bg — keep white text, just ensure it stays) */
body.lf-dark .lp-services-bg { background: #010409 !important; }
body.lf-dark .lp-svc h4      { color: #ffffff !important; }
body.lf-dark .lp-svc p       { color: rgba(255,255,255,.75) !important; }

/* Reviews */
body.lf-dark .lp-review        { background: #161b22 !important; border-color: #30363d !important; }
body.lf-dark .lp-review-text   { color: #c9d1d9 !important; }
body.lf-dark .lp-review-name   { color: #ffffff !important; }

/* FAQ */
body.lf-dark .lp-faq-item { border-bottom-color: #30363d !important; }
body.lf-dark .lp-faq-q    { color: #ffffff !important; }
body.lf-dark .lp-faq-a    { color: #c9d1d9 !important; }

/* Section backgrounds */
body.lf-dark #how,
body.lf-dark #pricing,
body.lf-dark #faq     { background-color: #0d1117 !important; }
body.lf-dark #reviews { background-color: #161b22 !important; }

/* Hero card */
body.lf-dark .lp-hero-card         { background: #1c2433 !important; border-color: #30363d !important; }
body.lf-dark .lp-hero-card-title   { color: #ffffff !important; }
body.lf-dark .price-row            { border-bottom-color: #30363d !important; }
body.lf-dark .price-row-label      { color: #ffffff !important; }
body.lf-dark .price-row-sub        { color: #8b949e !important; }
body.lf-dark .price-row-val        { color: #58a6ff !important; }

/* Auth modal */
body.lf-dark .auth-card    { background: #161b22 !important; border: 1px solid #30363d !important; }
body.lf-dark .auth-logo    { color: #ffffff !important; }
body.lf-dark .auth-tagline { color: #8b949e !important; }
body.lf-dark .auth-tab     { color: #8b949e !important; }
body.lf-dark .auth-tab.active { color: #58a6ff !important; border-bottom-color: #58a6ff !important; }
body.lf-dark .lfg label    { color: #8b949e !important; }
body.lf-dark .lfg input,
body.lf-dark .lfg select   { color: #ffffff !important; background: #0d1117 !important; border-color: #30363d !important; }
body.lf-dark .lfg input::placeholder { color: #484f58 !important; }

/* Nav */
body.lf-dark .lp-nav         { background: rgba(13,17,23,.97) !important; border-bottom-color: #30363d !important; }
body.lf-dark .lp-nav-logo    { color: #ffffff !important; }
body.lf-dark .lp-nav-links a { color: #8b949e !important; }
body.lf-dark .lp-nav-links a:hover { color: #ffffff !important; }

/* Footer */
body.lf-dark .lp-footer       { background: #010409 !important; }
body.lf-dark .lp-footer-logo  { color: #ffffff !important; }
body.lf-dark .lp-footer-col a { color: #484f58 !important; }
body.lf-dark .lp-footer-col a:hover { color: #ffffff !important; }

/* == SERVICES SECTION always has dark bg, always needs white text == */
.lp-services-bg .lp-section-title { color: #ffffff !important; }
.lp-services-bg .lp-section-sub   { color: rgba(255,255,255,.7) !important; }
.lp-services-bg .lp-eyebrow       { color: #7dd3fc !important; }
.lp-svc h4  { color: #ffffff !important; }
.lp-svc p   { color: rgba(255,255,255,.75) !important; }

/* == FOOTER always dark == */
.lp-footer .lp-footer-logo  { color: #ffffff !important; }
.lp-footer .lp-footer-col h5 { color: rgba(255,255,255,.9) !important; }
.lp-footer .lp-footer-col a  { color: rgba(255,255,255,.55) !important; }
.lp-footer .lp-footer-col a:hover { color: #ffffff !important; }
.lp-footer-bottom span       { color: rgba(255,255,255,.45) !important; }

/* == CTA BANNER always has colored bg == */
.lp-cta-bg h2 { color: #ffffff !important; }
.lp-cta-bg p  { color: rgba(255,255,255,.9) !important; }
"""

content = content[:style_close] + TARGETED_CSS + '\n' + content[style_close:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify
opens = content.count('<style')
closes = content.count('</style>')
print(f"style: opens={opens} closes={closes}")
print(f"File size: {len(content)}")
print("Done!")
