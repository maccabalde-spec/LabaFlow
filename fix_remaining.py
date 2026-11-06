"""
Fix ALL remaining ₱ used as ternary ? operators in JS template expressions.
Also fix → HTML entity used inside JS strings.
"""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ── Fix 1: ₱ inside template literal ${...} expressions ─────────────────
# Pattern: inside ${ ... } blocks, ₱ is always a ternary ?
# Simple approach: replace ₱ when surrounded by JS-like tokens

# These specific patterns were missed by the tokenizer:
specific_fixes = [
    # Inside template literals - ternary operators
    ("t.channel==='CASH'₱'b-gray':'b-blue'",    "t.channel==='CASH'?'b-gray':'b-blue'"),
    ("o.colorDist==='WHITES'₱'b-gray':'b-blue'", "o.colorDist==='WHITES'?'b-gray':'b-blue'"),
    ("o.colorDist==='WHITES'₱'?Whites':'??Colored'", "o.colorDist==='WHITES'?'Whites':'Colored'"),
    ("t==='CLOTHES'₱'':'none'",  "t==='CLOTHES'?'':'none'"),
    ("t==='BEDSHEET'₱'':'none'", "t==='BEDSHEET'?'':'none'"),
    ("t==='COMFORTER'₱'':'none'","t==='COMFORTER'?'':'none'"),
    # Also fix → HTML entity inside JS strings  
    ("else{toast(`${o.num} → ${next}`);}",  "else{toast(`${o.num} → ${next}`);}"),
]

for old, new in specific_fixes:
    if old in content:
        content = content.replace(old, new)
        count += 1
        print(f"Fixed: {repr(old[:70])}")

# ── Fix 2: Aggressive - find ALL remaining ₱ that are ternary operators ─
# Pattern: letter/quote/paren/bracket then ₱ then quote/backtick/letter
# NOT preceded by peso context like peso() function or price display

def is_in_html_content(pos, content):
    """Check if position is inside HTML tag content (not JS)"""
    # Find the previous < and > 
    prev_lt = content.rfind('<', 0, pos)
    prev_gt = content.rfind('>', 0, pos)
    # If prev_gt > prev_lt, we're inside a tag attribute or between tags
    return prev_gt > prev_lt

# Find all remaining ₱ in script blocks that look like ternary
script_pattern = re.compile(r'<script(?![^>]*type=["\']module["\'])[^>]*>(.*?)</script>', re.DOTALL)

def fix_ternary_in_js(js_text):
    """Replace ₱ that acts as ternary ? in JS expressions"""
    fixed = js_text
    n_fixed = 0
    
    # Pattern: identifier/string-end/paren-close then ₱ then string-start/identifier
    # Matches: ===X₱'string' or )₱'string' or ===X₱`string`
    patterns = [
        # After comparison operator
        (r"(===\s*'[^']*')\s*₱\s*(')", r"\1?\2"),
        (r"(===\s*'[^']*')\s*₱\s*(`)", r"\1?`"),
        # After closing paren
        (r"(\))\s*₱\s*(')", r"\1?'"),
        (r"(\))\s*₱\s*(`)", r"\1?`"),
        # After identifier/number
        (r"([a-zA-Z0-9_])\s*₱\s*(')", r"\1?'"),
        (r"([a-zA-Z0-9_])\s*₱\s*(`)", r"\1?`"),
        # Before string literal with quotes
        (r"₱\s*'([^']*)'(\s*:)", r"?'\1'\2"),
        # Common: ===value₱trueVal:falseVal
        (r"===([^₱\n]{1,30})₱([^:\n]{1,30}):", r"===\1?\2:"),
    ]
    
    for pat, repl in patterns:
        new_fixed = re.sub(pat, repl, fixed)
        diff = fixed.count('₱') - new_fixed.count('₱')
        if diff > 0:
            n_fixed += diff
            fixed = new_fixed
    
    return fixed, n_fixed

total_regex_fixes = 0
def process_script(m):
    global total_regex_fixes
    js = m.group(2)
    fixed_js, n = fix_ternary_in_js(js)
    total_regex_fixes += n
    return m.group(1) + fixed_js + m.group(3)

content = script_pattern.sub(process_script, content)
print(f"\nRegex ternary fixes: {total_regex_fixes}")

# ── Fix 3: Fix → HTML entities inside JavaScript strings ─────────────────
# → should be → in HTML but → (unicode) or → in JS strings
# The fix_all_symbols.py introduced → inside JS template literals

js_arrow_fixes = [
    # In JS toast/template - use unicode arrow instead of HTML entity
    ('toast(`${o.num} → ${next}`)', 'toast(`${o.num} \u2192 ${next}`)'),
    # Button text that's inside innerHTML template strings
    ('>Book This Service →<',    '>Book This Service →<'),   # HTML - keep
    ('>Get Started →<',          '>Get Started →<'),          # HTML - keep
    ('>Create Free Account →<',  '>Create Free Account →<'), # HTML - keep
    # JS string versions
    ("'→'",  "'→'"),  # keep in HTML context
]

# Only fix → inside script tags
def fix_arrow_in_script(m):
    js = m.group(2)
    # Replace → (HTML entity) with actual → character inside JS
    js = js.replace('→', '→')
    return m.group(1) + js + m.group(3)

content = script_pattern.sub(fix_arrow_in_script, content)
print("Fixed → HTML entities in JS")

# ── Fix 4: Fix remaining '?' placeholders that should be ₱ in HTML ───────
# These are in HTML content (not JS), outside script tags
# Pattern: >?180, >?190, >?200, >?25, >?38 etc in HTML
html_price_fixes = [
    ('>?180<', '>₱180<'),
    ('>?190<', '>₱190<'),
    ('>?200<', '>₱200<'),
    ('>?25<',  '>₱25<'),
    ('>?38<',  '>₱38<'),
    ('>?1 ',   '>₱1 '),
    ('+?25 ',  '+₱25 '),
    ('+?38 ',  '+₱38 '),
    ('?180 ',  '₱180 '),
    ('?190 ',  '₱190 '),
    ('?200 ',  '₱200 '),
    # promo tag in HTML
    ("??${t.promoCode}</span>", "${t.promoCode}</span>"),
    ("?Whites", "Whites"),
    ("??Colored", "Colored"),
]

for old, new in html_price_fixes:
    if old in content:
        content = content.replace(old, new)
        count += 1
        print(f"Fixed HTML price: {repr(old)}")

# ── Fix 5: Fix '—' / '' in JS template literals ─────────────────────────
fixes_misc = [
    # In JS template strings, use — (em dash unicode) not HTML entity
    ("return'—'", "return'\u2014'"),
    (":'—'",      ":'\u2014'"),
    ("'—'",       "'\u2014'"),  # inside JS
]

# Apply only inside script blocks
def fix_misc_in_script(m):
    js = m.group(2)
    for old, new in fixes_misc:
        js = js.replace(old, new)
    return m.group(1) + js + m.group(3)

content = script_pattern.sub(fix_misc_in_script, content)
print("Fixed em-dash HTML entities in JS")

print(f"\nTotal specific fixes: {count}")
print(f"Total regex fixes: {total_regex_fixes}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
