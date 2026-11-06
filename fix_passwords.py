path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

count = 0

# ── Step 1: Add CSS for password wrapper + eye button ────────────────────
pw_css = """
/* ── PASSWORD FIELD WITH EYE TOGGLE ── */
.pw-wrap{position:relative;display:flex;align-items:center;}
.pw-wrap input{width:100%;padding-right:38px;}
.pw-eye{position:absolute;right:10px;background:none;border:none;cursor:pointer;font-size:15px;color:var(--lp-muted);padding:0;line-height:1;user-select:none;}
.pw-eye:hover{color:var(--lp-text);}
/* Dark mode */
body.lf-dark .pw-eye{color:#8b949e;}
body.lf-dark .pw-eye:hover{color:#e6edf3;}
"""

# Insert CSS before the closing </style> of the first style block
# Find the GCASH section comment which we know comes after our CSS area
css_anchor = '/* ── GOOGLE SIGN-IN BUTTON ── */'
if css_anchor in content:
    content = content.replace(css_anchor, pw_css + '\n' + css_anchor)
    print("✓ Added password eye CSS")
    count += 1

# ── Step 2: Add JS function for toggling password visibility ─────────────
pw_js = """
/* Toggle password field visibility */
function togglePw(fieldId, btn){
  const inp = g(fieldId);
  if(!inp) return;
  const show = inp.type === 'password';
  inp.type = show ? 'text' : 'password';
  btn.textContent = show ? '🙈' : '👁';
}
"""

# Insert before the openAuth function
auth_anchor = 'function openAuth(tab){'
if auth_anchor in content:
    content = content.replace(auth_anchor, pw_js + '\n' + auth_anchor)
    print("✓ Added togglePw() JS function")
    count += 1

# ── Step 3: Replace password inputs with wrapped versions ────────────────

# Helper: wrap a password input with eye button
def wrap_pw(input_html, field_id):
    return f'<div class="pw-wrap">{input_html}<button type="button" class="pw-eye" onclick="togglePw(\'{field_id}\',this)" tabindex="-1">👁</button></div>'

# Find and replace each password field by ID
import re

# Sign In - liPass
old1 = re.search(r'<input type="password" id="liPass"[^>]*>', content)
if old1:
    original = old1.group(0)
    # Fix placeholder encoding + wrap
    fixed = re.sub(r'placeholder="[^"]*"', 'placeholder="Password"', original)
    content = content.replace(
        f'<label>Password</label>{original}',
        f'<label>Password</label>{wrap_pw(fixed, "liPass")}'
    )
    # Also handle lfg wrapper
    content = content.replace(original, wrap_pw(fixed, "liPass"), 1)
    print("✓ Wrapped liPass with eye icon")
    count += 1

# Register - rPass
old2 = re.search(r'<input type="password" id="rPass"[^>]*>', content)
if old2:
    original = old2.group(0)
    wrapped = wrap_pw(original, "rPass")
    content = content.replace(original, wrapped, 1)
    print("✓ Wrapped rPass with eye icon")
    count += 1

# Register - rPass2
old3 = re.search(r'<input type="password" id="rPass2"[^>]*>', content)
if old3:
    original = old3.group(0)
    wrapped = wrap_pw(original, "rPass2")
    content = content.replace(original, wrapped, 1)
    print("✓ Wrapped rPass2 with eye icon")
    count += 1

# Profile - prPass
old4 = re.search(r'<input type="password" id="prPass"[^>]*>', content)
if old4:
    original = old4.group(0)
    # Fix placeholder encoding
    fixed = re.sub(r'placeholder="[^"]*"', 'placeholder="Leave blank to keep current"', original)
    content = content.replace(original, wrap_pw(fixed, "prPass"), 1)
    print("✓ Wrapped prPass with eye icon")
    count += 1

# Admin manage user - muPass
old5 = re.search(r'<input type="password" id="muPass"[^>]*>', content)
if old5:
    original = old5.group(0)
    wrapped = wrap_pw(original, "muPass")
    content = content.replace(original, wrapped, 1)
    print("✓ Wrapped muPass with eye icon")
    count += 1

print(f"\nTotal: {count} changes")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
