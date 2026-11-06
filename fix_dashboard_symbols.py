path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0
fixes = [
    # ── HTML content ────────────────────────────────────────────────────

    # Customer portal topbar theme button (second instance)
    # Already has one fixed, need to find the second ??
    ('>??</button>\n\n      </div>\n\n    </div>',
     '>🌙</button>\n\n      </div>\n\n    </div>'),

    # Restock modal cost label
    ('<label>Cost per Unit (?) — for purchase log</label>',
     '<label>Cost per Unit (₱) — for purchase log</label>'),

    # ── JS nav items (ni: icons) ─────────────────────────────────────────
    ("{id:'promos',ni:'??',label:'Promo Codes'}",
     "{id:'promos',ni:'🎟️',label:'Promo Codes'}"),

    # ── JS search results icons ──────────────────────────────────────────
    # Order number search result
    ("icon:'??',label:o.num,sub:o.custName",
     "icon:'📋',label:o.num,sub:o.custName"),
    # Customer name search result
    ("icon:'??',label:o.custName,sub:`${cnt}",
     "icon:'👤',label:o.custName,sub:`${cnt}"),
    # Status filter search result
    ("icon:'??',label:s,sub:'Filter by status'",
     "icon:'🔖',label:s,sub:'Filter by status'"),
    # Service type filter search result
    ("icon:'??',label:v,sub:'Filter by service'",
     "icon:'🧺',label:v,sub:'Filter by service'"),

    # ── JS order status notifications ────────────────────────────────────
    # Order placed notification emoji
    ("'??'",    "'🧺'"),   # default fallback — will catch multiple, fix individually below

    # Laundry ready swal success
    ("swalSuccess('Laundry Ready! ??',",
     "swalSuccess('Laundry Ready! ✅',"),

    # Order status icons
    ("RECEIVED:{icon:'??',title:`Order",
     "RECEIVED:{icon:'📡',title:`Order"),
    ("PROCESSING:{icon:'??',title:`Order",
     "PROCESSING:{icon:'🫧',title:`Order"),
    ("RELEASED:{icon:'??',title:`Order",
     "RELEASED:{icon:'🎉',title:`Order"),

    # Loyalty tier discount notice
    ("??<strong>${tier.name} Member:",
     "⭐ <strong>${tier.name} Member:"),

    # Order placed push notification (seller side)
    ("Drop off at the shop!`,'??'",
     "Drop off at the shop!`,'🧺'"),
    ("Drop off at the shop.`,'??'",
     "Drop off at the shop.`,'🧺'"),

    # Platinum tier message
    ("??You have reached Platinum",
     "🏆 You have reached Platinum"),

    # ── JS call/mute toggle ──────────────────────────────────────────────
    # Mute toggle: muted vs unmuted
    ("if(btn)btn.textContent=_callMuted?'??':'??';",
     "if(btn)btn.textContent=_callMuted?'🔇':'🎤';"),

    # ── JS theme button update function ─────────────────────────────────
    # updateThemeBtns sets button text
    ("b.textContent=isLightApp?'??':'??';",
     "b.textContent=isLightApp?'☀️':'🌙';"),

    # ── JS default notification icon ────────────────────────────────────
    ("icon=icon||'??';",
     "icon=icon||'🔔';"),

    # ── JS seller bell when no notifications ────────────────────────────
    ("cnt}</span>`:'??';",
     "cnt}</span>`:'🔔';"),

    # ── JS top customer in dashboard ────────────────────────────────────
    ("padding:12px 0 0;border-top:1px solid var(--border);margin-top:4px;font-size:12px;color:var(--text-muted);\">??Top",
     "padding:12px 0 0;border-top:1px solid var(--border);margin-top:4px;font-size:12px;color:var(--text-muted);\">🏆 Top"),

    # Order placed notification from customer portal
    ("booking is confirmed. Drop off at the shop!`,'??'",
     "booking is confirmed. Drop off at the shop!`,'🧺'"),
]

for old, new in fixes:
    c = content.count(old)
    if c > 0 and old != new:
        content = content.replace(old, new)
        count += c
        print(f"  ✓ Fixed {c}x: {repr(old[:70])}")
    elif c == 0 and old != new:
        print(f"  ✗ NOT FOUND: {repr(old[:70])}")

# Fix remaining ?? in pushNotif calls (catch-all for order placed emojis)
import re
# pushNotif calls with ?? emoji
def fix_pushnotif(m):
    s = m.group(0)
    if '??' in s:
        return s.replace("'??'", "'🧺'").replace('"??"', '"🧺"')
    return s

content = re.sub(r"pushNotif\([^)]+\)", fix_pushnotif, content)

print(f"\nTotal: {count} fixes applied")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
