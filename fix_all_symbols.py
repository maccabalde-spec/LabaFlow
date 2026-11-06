"""
Comprehensive fix for ALL broken symbols, emojis, and characters in LabaFlow.html.
"""
path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

fixes = []

# ── LANDING PAGE HTML ────────────────────────────────────────────────────

# Navbar theme button
fixes += [
    ("?₱Dark",              "🌙 Dark"),
    ("☀️ Light",             "☀️ Light"),   # already ok if present
]

# Hero eyebrow - the span dot is fine, no fix needed

# Hero note badges
fixes += [
    ("₱Walk-in welcome",    "✅ Walk-in welcome"),
    ("₱GCash & Cash accepted", "💳 GCash & Cash accepted"),
    ("₱RFID-tracked",       "📡 RFID-tracked"),
]

# Hero card
fixes += [
    ("?₱Our Pricing",       "💰 Our Pricing"),
    ("Get Started ?",        "Get Started →"),
]

# Price rows - ₱ sign in prices (these should stay as ₱ but with proper format)
fixes += [
    ("<div class=\"price-row-val\">?180</div>",  "<div class=\"price-row-val\">₱180</div>"),
    ("<div class=\"price-row-val\">?190</div>",  "<div class=\"price-row-val\">₱190</div>"),
    ("<div class=\"price-row-val\">?200</div>",  "<div class=\"price-row-val\">₱200</div>"),
    ("Base 5 kg — +?38/kg extra",  "Base 5 kg — +₱38/kg extra"),
    ("Base 7 kg — +?25/kg extra",  "Base 7 kg — +₱25/kg extra"),
    ("+?25/kg extra",   "+₱25/kg extra"),
    ("+?38/kg extra",   "+₱38/kg extra"),
]

# How It Works steps
fixes += [
    # Step 01 - Book or Walk In
    ('<span class="lp-step-icon">??</span>\n\n        <h4>Book or Walk In</h4>',
     '<span class="lp-step-icon">📋</span>\n\n        <h4>Book or Walk In</h4>'),
    # Step 02 - RFID Tag
    ('<span class="lp-step-icon">??</span>\n\n        <h4>RFID Tag Assigned</h4>',
     '<span class="lp-step-icon">📡</span>\n\n        <h4>RFID Tag Assigned</h4>'),
    # Step 03 - Wash & Dry
    ('<span class="lp-step-icon">??</span>\n\n        <h4>We Wash &amp; Dry</h4>',
     '<span class="lp-step-icon">🫧</span>\n\n        <h4>We Wash &amp; Dry</h4>'),
    # Step 04 - Pickup
    ('<span class="lp-step-icon">?</span>\n\n        <h4>Ready for Pickup</h4>',
     '<span class="lp-step-icon">✅</span>\n\n        <h4>Ready for Pickup</h4>'),
]

# Services section icons
fixes += [
    ('<span class="lp-svc-icon">??</span>\n\n          <h4>Clothes Wash</h4>',
     '<span class="lp-svc-icon">👕</span>\n\n          <h4>Clothes Wash</h4>'),
    ('<span class="lp-svc-icon">???</span>\n\n          <h4>Bedsheet Wash</h4>',
     '<span class="lp-svc-icon">🛏️</span>\n\n          <h4>Bedsheet Wash</h4>'),
    ('<span class="lp-svc-icon">??</span>\n\n          <h4>Comforter Wash</h4>',
     '<span class="lp-svc-icon">🛋️</span>\n\n          <h4>Comforter Wash</h4>'),
    ('<span class="lp-svc-icon">??</span>\n\n          <h4>Surf Liquid Detergent</h4>',
     '<span class="lp-svc-icon">🧴</span>\n\n          <h4>Surf Liquid Detergent</h4>'),
    ('<span class="lp-svc-icon">??</span>\n\n          <h4>Surf Fabric Conditioner</h4>',
     '<span class="lp-svc-icon">🌸</span>\n\n          <h4>Surf Fabric Conditioner</h4>'),
    ('<span class="lp-svc-icon">?</span>\n\n          <h4>Zonrox Color Safe</h4>',
     '<span class="lp-svc-icon">🧪</span>\n\n          <h4>Zonrox Color Safe</h4>'),
]

# Service badges pricing
fixes += [
    ('<div class="lp-svc-badge">?180 / 7kg base</div>', '<div class="lp-svc-badge">₱180 / 7kg base</div>'),
    ('<div class="lp-svc-badge">?190 / 5kg base</div>', '<div class="lp-svc-badge">₱190 / 5kg base</div>'),
    ('<div class="lp-svc-badge">?200 / piece</div>',    '<div class="lp-svc-badge">₱200 / piece</div>'),
]

# Pricing cards
fixes += [
    ('"lp-price-card-name">?₱Clothes Wash</div>',   '"lp-price-card-name">👕 Clothes Wash</div>'),
    ('"lp-price-card-name">??₱Bedsheet Wash</div>',  '"lp-price-card-name">🛏️ Bedsheet Wash</div>'),
    ('"lp-price-card-name">?₱Comforter Wash</div>',  '"lp-price-card-name">🛋️ Comforter Wash</div>'),
    ('<sup>?</sup>180',  '<sup>₱</sup>180'),
    ('<sup>?</sup>190',  '<sup>₱</sup>190'),
    ('<sup>?</sup>200',  '<sup>₱</sup>200'),
    ('<li>+?25 per kg above 7 kg</li>', '<li>+₱25 per kg above 7 kg</li>'),
    ('<li>+?38 per kg above 5 kg</li>', '<li>+₱38 per kg above 5 kg</li>'),
    ('<li>Flat ?200 per piece</li>',    '<li>Flat ₱200 per piece</li>'),
]

# Reviews section
fixes += [
    ("?₱Leave a Review",    "⭐ Leave a Review"),
    ('<div class="lp-rating-big" id="lpRatingBig">—</div>',
     '<div class="lp-rating-big" id="lpRatingBig">—</div>'),  # keep
    # Star selects
    ('"lp-star-select" id="rvStars" data-rating="5">\n\n        <span onclick="setReviewStar(1)">?</span>\n\n        <span onclick="setReviewStar(2)">?</span>\n\n        <span onclick="setReviewStar(3)">?</span>\n\n        <span onclick="setReviewStar(4)">?</span>\n\n        <span onclick="setReviewStar(5)" class="active">?</span>',
     '"lp-star-select" id="rvStars" data-rating="5">\n\n        <span onclick="setReviewStar(1)">★</span>\n\n        <span onclick="setReviewStar(2)">★</span>\n\n        <span onclick="setReviewStar(3)">★</span>\n\n        <span onclick="setReviewStar(4)">★</span>\n\n        <span onclick="setReviewStar(5)" class="active">★</span>'),
]

# FAQ - ₱ used as question mark in FAQ questions
fixes += [
    ("How does the RFID tracking work₱<span",   "How does the RFID tracking work?<span"),
    ("What detergents and products do you use₱<span", "What detergents and products do you use?<span"),
    ("How is the price calculated₱<span",        "How is the price calculated?<span"),
    ("What payment methods do you accept₱<span", "What payment methods do you accept?<span"),
    ("What are LabaPoints and how do they work₱<span", "What are LabaPoints and how do they work?<span"),
    ("Can I track my order as a customer₱<span", "Can I track my order as a customer?<span"),
    ("Do you accept special instructions₱<span", "Do you accept special instructions?<span"),
]

# FAQ answers with broken pricing
fixes += [
    ("Clothes: ?180 base for 7 kg, +?25",  "Clothes: ₱180 base for 7 kg, +₱25"),
    ("Bedsheets: ?190 base for 5 kg, +?38", "Bedsheets: ₱190 base for 5 kg, +₱38"),
    ("Comforters: flat ?200 per piece",      "Comforters: flat ₱200 per piece"),
    ("Every ?1 spent earns 1 LabaPoint",     "Every ₱1 spent earns 1 LabaPoint"),
]

# CTA banner
fixes += [
    ("Create Free Account ?",  "Create Free Account →"),
]

# Hero description
fixes += [
    ("wash, dry, fold, and have it ready for pickup. RFID-tracked orders",
     "wash, dry, fold, and have it ready for pickup. RFID-tracked orders"),  # OK
]

# ── APP SHELL ────────────────────────────────────────────────────────────

# Theme toggle in app
fixes += [
    ("'🌙 Dark'",    "'🌙 Dark'"),   # already fixed
]

# Nav items (already fixed by fix_emojis.py but double-check)

# ── JS FUNCTIONS ─────────────────────────────────────────────────────────

# Loading messages
fixes += [
    ("showLoader('Signing in…')",         "showLoader('Signing in...')"),
    ("Loading…",                          "Loading..."),
    ("showLoader('Connecting to Google…')","showLoader('Connecting to Google...')"),
    ("showLoader('Creating account…')",   "showLoader('Creating account...')"),
    ("showLoader('Signing out…')",        "showLoader('Signing out...')"),
    ("showLoader('Loading data…')",       "showLoader('Loading data...')"),
    ("showLoader('Signing in with Google…')", "showLoader('Signing in with Google...')"),
]

# ── Apply all fixes ──────────────────────────────────────────────────────
count = 0
for old, new in fixes:
    if old != new and old in content:
        content = content.replace(old, new)
        count += 1
        print(f"  ✓ {repr(old[:60])}")

print(f"\nTotal: {count} fixes applied")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
