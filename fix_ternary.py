"""
Fix: ₱ (U+20B1) was incorrectly replacing ? (ternary operator)
in JavaScript code throughout LabaFlow.html.

Rule:
  - ₱ INSIDE a string literal ('₱' or `₱`) → KEEP (it's the peso sign)
  - ₱ OUTSIDE a string literal (as operator) → replace with ?

This is done by tokenizing each script block carefully.
"""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

PESO = '₱'
QUESTION = '?'

def fix_js_ternaries(js_code):
    """
    Replace ₱ that acts as ternary operator (not inside strings) with ?
    """
    result = []
    i = 0
    n = len(js_code)
    
    while i < n:
        ch = js_code[i]
        
        # Single-quoted string — skip entire string content
        if ch == "'":
            result.append(ch)
            i += 1
            while i < n and js_code[i] != "'":
                if js_code[i] == '\\':
                    result.append(js_code[i])
                    i += 1
                if i < n:
                    result.append(js_code[i])
                    i += 1
            if i < n:
                result.append(js_code[i])  # closing '
                i += 1
            continue
        
        # Double-quoted string
        if ch == '"':
            result.append(ch)
            i += 1
            while i < n and js_code[i] != '"':
                if js_code[i] == '\\':
                    result.append(js_code[i])
                    i += 1
                if i < n:
                    result.append(js_code[i])
                    i += 1
            if i < n:
                result.append(js_code[i])  # closing "
                i += 1
            continue
        
        # Template literal (backtick string) — more complex but handle basic
        if ch == '`':
            result.append(ch)
            i += 1
            depth = 0
            while i < n:
                c2 = js_code[i]
                if c2 == '\\':
                    result.append(c2)
                    i += 1
                    if i < n:
                        result.append(js_code[i])
                        i += 1
                    continue
                if c2 == '$' and i+1 < n and js_code[i+1] == '{':
                    depth += 1
                    result.append(c2)
                    i += 1
                    continue
                if c2 == '}' and depth > 0:
                    depth -= 1
                if c2 == '`' and depth == 0:
                    result.append(c2)
                    i += 1
                    break
                # Inside template literal: keep ₱ in string parts
                # but if inside ${...} expression, fix ternaries
                if depth > 0 and c2 == PESO:
                    result.append(QUESTION)
                else:
                    result.append(c2)
                i += 1
            continue
        
        # Line comment
        if ch == '/' and i+1 < n and js_code[i+1] == '/':
            while i < n and js_code[i] != '\n':
                result.append(js_code[i])
                i += 1
            continue
        
        # Block comment
        if ch == '/' and i+1 < n and js_code[i+1] == '*':
            result.append(ch)
            i += 1
            while i < n - 1:
                result.append(js_code[i])
                if js_code[i] == '*' and js_code[i+1] == '/':
                    result.append(js_code[i+1])
                    i += 2
                    break
                i += 1
            continue
        
        # ₱ outside a string → it's a corrupted ternary ?
        if ch == PESO:
            result.append(QUESTION)
            i += 1
            continue
        
        result.append(ch)
        i += 1
    
    return ''.join(result)


# Process all non-module script blocks
def process_html(html):
    # Find all <script> blocks (not type=module)
    pattern = re.compile(
        r'(<script(?![^>]*type=["\']module["\'])[^>]*>)(.*?)(</script>)',
        re.DOTALL
    )
    
    total_fixed = 0
    
    def replace_script(m):
        nonlocal total_fixed
        open_tag  = m.group(1)
        js_code   = m.group(2)
        close_tag = m.group(3)
        
        fixed = fix_js_ternaries(js_code)
        
        # Count fixes
        fixed_count = js_code.count(PESO) - fixed.count(PESO)
        if fixed_count > 0:
            total_fixed += fixed_count
            start_line = html[:m.start()].count('\n') + 1
            print(f"  Fixed {fixed_count} ternaries in script block at line {start_line}")
        
        return open_tag + fixed + close_tag
    
    result = pattern.sub(replace_script, html)
    print(f"\nTotal ternary fixes: {total_fixed}")
    return result


print("Fixing ₱ → ? ternary operator corruption...\n")
fixed_content = process_html(content)

# Verify: count remaining ₱ in script blocks
script_blocks = re.findall(r'<script(?![^>]*type=["\']module["\'])[^>]*>(.*?)</script>', fixed_content, re.DOTALL)
peso_in_scripts = sum(b.count(PESO) for b in script_blocks)
print(f"\n₱ signs remaining in script blocks: {peso_in_scripts}")
print("(These should only be inside string literals like '₱' or `₱180`)")

# Spot check: show remaining ₱ contexts
for block in script_blocks:
    for m in re.finditer(r'.{0,30}₱.{0,30}', block):
        ctx = m.group()
        print(f"  Remaining: {repr(ctx)}")

# Write fixed file
with open(path, 'w', encoding='utf-8') as f:
    f.write(fixed_content)

print(f"\nFile written: {len(fixed_content)} chars")
print("Done!")
