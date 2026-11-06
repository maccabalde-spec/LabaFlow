path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the </style> tag and insert our comprehensive text color fix just before it
style_end = content.find('</style>')

NEW_CSS = """
/* ════════════════════════════════════════
   TEXT COLOR SYSTEM
   Dark mode  = white text
   Light mode = black/dark text
   Simple, reliable, covers everything
════════════════════════════════════════ */

/* ── LIGHT MODE (default) — dark text on light bg ── */
body:not(.lf-dark) {
  color: #111827;
  background: #f8f9fa;
}
body:not(.lf-dark) h1,
body:not(.lf-dark) h2,
body:not(.lf-dark) h3,
body:not(.lf-dark) h4,
body:not(.lf-dark) h5,
body:not(.lf-dark) h6 { color: #111827; }
body:not(.lf-dark) p   { color: #374151; }
body:not(.lf-dark) a   { color: #0284c7; }

body:not(.lf-dark) .lp-section-title { color: #111827 !important; }
body:not(.lf-dark) .lp-section-sub   { color: #374151 !important; }
body:not(.lf-dark) .lp-eyebrow       { color: #0284c7 !important; }

/* Steps */
body:not(.lf-dark) .lp-step       { background: #ffffff; border-color: #e5e7eb; }
body:not(.lf-dark) .lp-step h4    { color: #111827 !important; }
body:not(.lf-dark) .lp-step p     { color: #374151 !important; }
body:not(.lf-dark) .lp-step-body  { background: #ffffff; }

/* Pricing */
body:not(.lf-dark) .lp-price-card          { background: #ffffff !important; }
body:not(.lf-dark) .lp-price-card-label    { color: #6b7280 !important; }
body:not(.lf-dark) .lp-price-card-name     { color: #111827 !important; }
body:not(.lf-dark) .lp-price-card-price    { color: #0284c7 !important; }
body:not(.lf-dark) .lp-price-card-desc     { color: #374151 !important; }
body:not(.lf-dark) .lp-price-features li   { color: #111827 !important; }

/* Reviews */
body:not(.lf-dark) .lp-review        { background: #ffffff; }
body:not(.lf-dark) .lp-review-text   { color: #111827 !important; }
body:not(.lf-dark) .lp-review-name   { color: #111827 !important; }
body:not(.lf-dark) .lp-review-loc    { color: #6b7280 !important; }

/* FAQ */
body:not(.lf-dark) .lp-faq-q  { color: #111827 !important; }
body:not(.lf-dark) .lp-faq-a  { color: #374151 !important; }

/* Auth modal */
body:not(.lf-dark) .auth-card    { background: #ffffff; }
body:not(.lf-dark) .auth-logo    { color: #111827; }
body:not(.lf-dark) .auth-tagline { color: #6b7280; }
body:not(.lf-dark) .auth-tab     { color: #6b7280; }
body:not(.lf-dark) .lfg label    { color: #6b7280; }
body:not(.lf-dark) .lfg input    { color: #111827; background: #f9fafb; }


/* ── DARK MODE — white text on dark bg ── */
body.lf-dark {
  color: #ffffff;
  background: #0d1117;
}
body.lf-dark h1,
body.lf-dark h2,
body.lf-dark h3,
body.lf-dark h4,
body.lf-dark h5,
body.lf-dark h6 { color: #ffffff !important; }
body.lf-dark p   { color: #c9d1d9 !important; }

body.lf-dark .lp-section-title { color: #ffffff !important; }
body.lf-dark .lp-section-sub   { color: #c9d1d9 !important; }
body.lf-dark .lp-eyebrow       { color: #58a6ff !important; }

/* Steps */
body.lf-dark .lp-step      { background: #161b22 !important; border-color: #30363d !important; }
body.lf-dark .lp-step h4   { color: #ffffff !important; }
body.lf-dark .lp-step p    { color: #c9d1d9 !important; }
body.lf-dark .lp-step-body { background: #161b22 !important; }
body.lf-dark .lp-step-num  { color: #58a6ff !important; background: rgba(88,166,255,.2) !important; }

/* Pricing */
body.lf-dark .lp-price-card         { background: #161b22 !important; border-color: #30363d !important; }
body.lf-dark .lp-price-card.featured{ background: #0d2137 !important; border-color: #388bfd !important; }
body.lf-dark .lp-price-card-label   { color: #8b949e !important; }
body.lf-dark .lp-price-card-name    { color: #ffffff !important; }
body.lf-dark .lp-price-card-price   { color: #58a6ff !important; }
body.lf-dark .lp-price-card-desc    { color: #c9d1d9 !important; }
body.lf-dark .lp-price-features li  { color: #c9d1d9 !important; border-bottom-color: #30363d !important; }
body.lf-dark .lp-price-features li::before { color: #58a6ff !important; }

/* Reviews */
body.lf-dark .lp-review        { background: #161b22 !important; border-color: #30363d !important; }
body.lf-dark .lp-review-text   { color: #c9d1d9 !important; font-style: italic; }
body.lf-dark .lp-review-name   { color: #ffffff !important; }
body.lf-dark .lp-review-loc    { color: #8b949e !important; }

/* FAQ */
body.lf-dark .lp-faq-item { border-bottom-color: #30363d !important; }
body.lf-dark .lp-faq-q    { color: #ffffff !important; }
body.lf-dark .lp-faq-q:hover { color: #58a6ff !important; }
body.lf-dark .lp-faq-a    { color: #c9d1d9 !important; }

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

/* Section backgrounds */
body.lf-dark #how,
body.lf-dark #pricing,
body.lf-dark #faq     { background-color: #0d1117 !important; }
body.lf-dark #reviews { background-color: #161b22 !important; }

/* Hero pricing card */
body.lf-dark .lp-hero-card            { background: #1c2433 !important; border-color: #30363d !important; }
body.lf-dark .lp-hero-card-title      { color: #ffffff !important; }
body.lf-dark .price-row               { border-bottom-color: #30363d !important; }
body.lf-dark .price-row-label         { color: #ffffff !important; }
body.lf-dark .price-row-sub           { color: #8b949e !important; }
body.lf-dark .price-row-val           { color: #58a6ff !important; }

/* Badges strip */
body.lf-dark .lp-badges { background: #010409 !important; }

/* Footer */
body.lf-dark .lp-footer        { background: #010409 !important; }
body.lf-dark .lp-footer-logo   { color: #ffffff !important; }
body.lf-dark .lp-footer-desc   { color: #484f58 !important; }
body.lf-dark .lp-footer-col h5 { color: rgba(255,255,255,.9) !important; }
body.lf-dark .lp-footer-col a  { color: #484f58 !important; }
body.lf-dark .lp-footer-col a:hover { color: #ffffff !important; }

/* Nav */
body.lf-dark .lp-nav          { background: rgba(13,17,23,.97) !important; border-bottom-color: #30363d !important; }
body.lf-dark .lp-nav-logo     { color: #ffffff !important; }
body.lf-dark .lp-nav-links a  { color: #8b949e !important; }
body.lf-dark .lp-nav-links a:hover { color: #ffffff !important; }
"""

content = content[:style_end] + NEW_CSS + '\n' + content[style_end:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify
opens = content.count('<style')
closes = content.count('</style>')
print(f"style: opens={opens} closes={closes}")
print(f"File size: {len(content)}")
print("Done!")
