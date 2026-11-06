"""
Fix remaining corruptions in LabaFlow.html:
1. ni:'₱' → nav icons that were emojis
2. ?₱ patterns → corrupted emoji+text  
3. title:'₱...' → corrupted emoji titles
"""
path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# These are nav icon 'ni' fields that had emoji replaced with ₱
# Restore appropriate emojis for each nav item
nav_fixes = [
    ("ni:'₱',label:'Dashboard'",        "ni:'📊',label:'Dashboard'"),
    ("ni:'₱',label:'Financial Analytics'","ni:'💰',label:'Financial Analytics'"),
    ("ni:'₱',label:'Inventory Monitor'", "ni:'📦',label:'Inventory Monitor'"),
    ("ni:'₱',label:'User Accounts'",     "ni:'👥',label:'User Accounts'"),
    ("ni:'₱',label:'Orders'",            "ni:'🧺',label:'Orders'"),
    ("ni:'₱',label:'Inventory'",         "ni:'🫧',label:'Inventory'"),
    ("ni:'₱',label:'Reports'",           "ni:'📈',label:'Reports'"),
    ("ni:'₱',label:'Messages'",          "ni:'💬',label:'Messages'"),
    ("ni:'₱',label:'RFID Tags'",         "ni:'📡',label:'RFID Tags'"),
    ("ni:'₱',label:'Settings'",          "ni:'⚙️',label:'Settings'"),
]

# Fix heading titles with ?₱ or ₱ prefix (corrupted emoji)
heading_fixes = [
    # Chart/section headings
    ("<h4>?₱Revenue</h4>",              "<h4>💰 Revenue</h4>"),
    ("<h4>?₱Inventory Snapshot</h4>",   "<h4>📦 Inventory Snapshot</h4>"),
    ("<h4>?₱Busiest Days of Week</h4>", "<h4>📅 Busiest Days of Week</h4>"),
    ("<h4>?₱Orders by Service Type</h4>","<h4>🧺 Orders by Service Type</h4>"),
    ("<h4>??₱Recent Orders</h4>",       "<h4>📋 Recent Orders</h4>"),
    ("<h4>?₱Orders & Revenue Over Time</h4>","<h4>📈 Orders & Revenue Over Time</h4>"),
    ("<h4>?₱Customer Order Frequency</h4>","<h4>👥 Customer Order Frequency</h4>"),
    ("<h4>?₱Revenue by Channel</h4>",   "<h4>💳 Revenue by Channel</h4>"),
    ("<h4>?₱Order Activity by Hour of Day</h4>","<h4>⏰ Order Activity by Hour of Day</h4>"),
    ("<h4>?₱Supply Inventory</h4>",     "<h4>🫧 Supply Inventory</h4>"),
    ("<h4>?₱Promo Codes</h4>",          "<h4>🎟️ Promo Codes</h4>"),
    ("<h4>?₱RFID Tags</h4>",            "<h4>📡 RFID Tags</h4>"),
    ("<h4>?₱Inventory</h4>",            "<h4>📦 Inventory</h4>"),
    # Loyalty/portal headings
    ("<h3>₱LabaPoints & Loyalty</h3>",  "<h3>⭐ LabaPoints & Loyalty</h3>"),
    ("<h3>?₱Notifications</h3>",        "<h3>🔔 Notifications</h3>"),
    # Shop settings
    ("<h4>₱Shop Settings</h4>",         "<h4>⚙️ Shop Settings</h4>"),
]

# Fix button labels
button_fixes = [
    ("?₱Save",          "💾 Save"),
    ("?₱Remove",        "🗑️ Remove"),
    ("?₱Record Payment Now", "💳 Record Payment Now"),
    ("?₱QR",            "📱 QR"),
    ("?₱RFID",          "📡 RFID"),
    (">?₱Call</button>",     ">📞 Call</button>"),
    (">?₱Video</button>",    ">📹 Video</button>"),
    (">?₱Call Shop</button>",">📞 Call Shop</button>"),
    (">?₱Video</button>",    ">📹 Video</button>"),
    ("btn.textContent='₱Record Payment to Release'", "btn.textContent='💳 Record Payment to Release'"),
]

# Fix theme toggle button text
theme_fixes = [
    ("isDarkLanding?'?₱Light':'?₱Dark'", "isDarkLanding?'☀️ Light':'🌙 Dark'"),
    ("type==='video'?'?₱Starting video call':'?₱Calling",
     "type==='video'?'📹 Starting video call...':'📞 Calling"),
]

# Fix toast/notification messages
notif_fixes = [
    ("toast(`₱₱+${pts} LabaPoints awarded", "toast(`⭐ +${pts} LabaPoints awarded"),
    ("else{toast(`${o.num} ₱${next}`);}", "else{toast(`${o.num} → ${next}`);}"),
    ("Low Stock Alert'", "Low Stock Alert'"),  # keep as is, title already has ₱ correctly
    ("READY:{icon:'₱'", "READY:{icon:'✅'"),
    (" +${pts} LabaPoints earned!`,'₱')", " +${pts} LabaPoints earned!`,'🎉')"),
    ("bell.innerHTML=cnt>0?`₱₱<span", "bell.innerHTML=cnt>0?`🔔<span"),
    ("ratingStars.textContent='₱'.repeat", "ratingStars.textContent='★'.repeat"),
    (")+'₱'.repeat(5-Math.round(parseFlo", ")+'☆'.repeat(5-Math.round(parseFlo"),
]

# Fix loyalty pill
loyalty_fixes = [
    ("pill.textContent=`₱ ${CU.points} pts", "pill.textContent=`⭐ ${CU.points} pts"),
    ("span style=\"color:var(--warn)\">?₱${tier.name}", "span style=\"color:var(--warn)\">⭐ ${tier.name}"),
]

# Fix promo/order display
order_fixes = [
    ("colorDist==='WHITES'?'₱Whites Only':'?₱Colored Only'", "colorDist==='WHITES'?'Whites Only':'Colored Only'"),
    ("promoCode?`<span class=\"promo-tag\">?₱${o.promoCode}</span>`", "promoCode?`<span class=\"promo-tag\">🎟️ ${o.promoCode}</span>`"),
    ("Paid?`<span class=\"badge b-ok\">₱Paid</span>`", "Paid?`<span class=\"badge b-ok\">✅ Paid</span>`"),
    ("simulate ringing ₱connected", "simulate ringing → connected"),
    ("color:'#fbbf24;font-size:10px;\">₱Unpaid</span>", "color:'#fbbf24;font-size:10px;\">⏳ Unpaid</span>"),
    ("style=\"font-size:10px;\">₱Paid</span>", "style=\"font-size:10px;\">✅ Paid</span>"),
    ("'₱QR image uploaded.", "'✅ QR image uploaded."),
    ("title:'₱Low Stock Alert'", "title:'⚠️ Low Stock Alert'"),
    ("promoMsg:'₱Invalid or expired promo code'", "promoMsg:'❌ Invalid or expired promo code'"),
    ("promoMsg:'₱Promo code already exhausted'}", "promoMsg:'❌ Promo code already exhausted'}"),
    ("promoMsg:`₱ ${pc.code}: ${pc.disc}% off", "promoMsg:`🎟️ ${pc.code}: ${pc.disc}% off"),
]

all_fixes = nav_fixes + heading_fixes + button_fixes + theme_fixes + notif_fixes + loyalty_fixes + order_fixes

count = 0
for old, new in all_fixes:
    if old in content:
        content = content.replace(old, new)
        count += 1
        print(f"  Fixed: {repr(old[:50])}")

print(f"\nTotal: {count} emoji/label fixes applied")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
