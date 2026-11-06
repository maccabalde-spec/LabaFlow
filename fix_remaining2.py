import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ── Fix all remaining ₱ as ternary operators using simple string replace ──
# These are the ones still remaining after previous fixes
ternary_fixes = [
    # In template literals inside ${...}
    ("t.channel==='CASH'₱'b-gray':'b-blue'",     "t.channel==='CASH'?'b-gray':'b-blue'"),
    ("o.colorDist==='WHITES'₱'b-gray':'b-blue'",  "o.colorDist==='WHITES'?'b-gray':'b-blue'"),
    ("o.colorDist==='WHITES'₱'?Whites':'??Colored'","o.colorDist==='WHITES'?'Whites':'Colored'"),
    ("t==='CLOTHES'₱'':'none'",   "t==='CLOTHES'?'':'none'"),
    ("t==='BEDSHEET'₱'':'none'",  "t==='BEDSHEET'?'':'none'"),
    ("t==='COMFORTER'₱'':'none'", "t==='COMFORTER'?'':'none'"),
    # Any remaining === X ₱ Y : Z patterns
    ("==='WHITES'₱",   "==='WHITES'?"),
    ("==='COLORED'₱",  "==='COLORED'?"),
    ("==='MIXED'₱",    "==='MIXED'?"),
    ("==='CASH'₱",     "==='CASH'?"),
    ("==='GCASH'₱",    "==='GCASH'?"),
    ("==='ADMIN'₱",    "==='ADMIN'?"),
    ("==='SELLER'₱",   "==='SELLER'?"),
    ("==='CUSTOMER'₱", "==='CUSTOMER'?"),
    ("==='RELEASED'₱", "==='RELEASED'?"),
    ("==='READY'₱",    "==='READY'?"),
    ("==='PENDING'₱",  "==='PENDING'?"),
    ("==='RECEIVED'₱", "==='RECEIVED'?"),
    ("==='PROCESSING'₱","==='PROCESSING'?"),
    ("==='CLOTHES'₱",  "==='CLOTHES'?"),
    ("==='BEDSHEET'₱", "==='BEDSHEET'?"),
    ("==='COMFORTER'₱","==='COMFORTER'?"),
    ("==='WASH_ONLY'₱","==='WASH_ONLY'?"),
    ("==='DRY_ONLY'₱", "==='DRY_ONLY'?"),
    ("==='COMPLETED'₱","==='COMPLETED'?"),
    ("==='video'₱",    "==='video'?"),
    ("==='audio'₱",    "==='audio'?"),
    ("==='dark'₱",     "==='dark'?"),
    ("==='light'₱",    "==='light'?"),
    ("==='sign'₱",     "==='sign'?"),
    ("==='reg'₱",      "==='reg'?"),
    # length/count checks
    ("length₱",        "length?"),
    # null checks
    ("null₱",          "null?"),
    # boolean
    (" true₱",         " true?"),
    (" false₱",        " false?"),
    # )₱ pattern (after closing paren)
    (")₱'",            ")?'"),
    (")₱`",            ")?`"),
    (")₱0",            ")?0"),
    (")₱1",            ")?1"),
    (")₱'none'",       ")? 'none'"),
    # number comparisons  
    (">0₱",            ">0?"),
    (">=0₱",           ">=0?"),
    ("===0₱",          "===0?"),
    ("===1₱",          "===1?"),
    ("!==0₱",          "!==0?"),
    # variable ? - common patterns
    ("rowPaid₱",       "rowPaid?"),
    ("isPaid₱",        "isPaid?"),
    ("tag₱",           "tag?"),
    ("topCust₱",       "topCust?"),
    ("o.tagId₱",       "o.tagId?"),
    ("o.notes₱",       "o.notes?"),
    ("o.kg₱",          "o.kg?"),
    ("o.comQty₱",      "o.comQty?"),
    ("o.finalPrice₱",  "o.finalPrice?"),
    ("o.promoCode₱",   "o.promoCode?"),
    ("o.discount₱",    "o.discount?"),
    ("i.packSize₱",    "i.packSize?"),
    ("i.perLoad₱",     "i.perLoad?"),
    ("costPerUnit₱",   "costPerUnit?"),
    ("u.pic₱",         "u.pic?"),
    ("cust₱",          "cust?"),
    ("t.gcashRef₱",    "t.gcashRef?"),
    ("nextTier₱",      "nextTier?"),
    ("isDark₱",        "isDark?"),
    ("isLight₱",       "isLight?"),
    ("cnt₱",           "cnt?"),
    ("unread₱",        "unread?"),
    ("changed₱",       "changed?"),
    ("low.length₱",    "low.length?"),
]

for old, new in ternary_fixes:
    c = content.count(old)
    if c > 0:
        content = content.replace(old, new)
        count += c
        print(f"Fixed {c}x: {repr(old)}")

# Fix → HTML entity inside JS template literals
# Find all occurrences of → inside <script> blocks
def fix_in_scripts(html, old, new):
    result = []
    i = 0
    while i < len(html):
        # Find next <script tag (non-module)
        script_start = html.find('<script', i)
        if script_start == -1:
            result.append(html[i:])
            break
        # Check it's not type=module
        tag_end = html.find('>', script_start)
        tag = html[script_start:tag_end+1]
        result.append(html[i:script_start])
        
        if 'type=' not in tag or 'module' not in tag:
            # Non-module script — find its end
            close = html.find('</script>', tag_end+1)
            if close == -1:
                result.append(html[script_start:])
                break
            js_content = html[tag_end+1:close]
            result.append(tag)
            result.append(js_content.replace(old, new))
            result.append('</script>')
            i = close + len('</script>')
        else:
            # Module script — skip
            close = html.find('</script>', tag_end+1)
            result.append(html[script_start:close+len('</script>')])
            i = close + len('</script>')
    
    return ''.join(result)

# Fix → in JS (should be plain arrow character)
c_before = content.count('→')
content = fix_in_scripts(content, '→', '→')
c_after = content.count('→')
if c_before != c_after:
    print(f"Fixed {c_before-c_after} → HTML entities in JS")

# Fix — in JS
content = fix_in_scripts(content, '—', '—')
print(f"Fixed — HTML entities in JS")

# Remaining broken promo tag
content = content.replace("??${t.promoCode}", "${t.promoCode}")
content = content.replace("??${o.promoCode}", "${o.promoCode}")
content = content.replace("?₱${", "${")   # any leftover ?₱ before template vars

print(f"\nTotal: {count} ternary fixes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
