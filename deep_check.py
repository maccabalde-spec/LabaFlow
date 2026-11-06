"""
Deep check: find the EXACT first syntax error in the HTML file
by trying to parse each script block with Python's JS-like approach.
Also checks for any remaining ₱ used as operators.
"""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()
    lines = content.split('\n')

# Find all script blocks with line numbers
pattern = re.compile(r'<script(?![^>]*type=["\']module["\'])[^>]*>(.*?)</script>', re.DOTALL)

print("=== Script block analysis ===\n")

for m in pattern.finditer(content):
    start_line = content[:m.start()].count('\n') + 1
    end_line   = content[:m.end()].count('\n') + 1
    js = m.group(1)
    
    opens  = js.count('{')
    closes = js.count('}')
    parens_o = js.count('(')
    parens_c = js.count(')')
    
    issues = []
    if opens != closes:
        issues.append(f"BRACE MISMATCH: {{ {opens} vs }} {closes}")
    
    # Check for ₱ outside strings (as operator)
    # Simple heuristic: ₱ followed by space then string quote
    peso_ops = re.findall(r"[^'`\"\\]₱[^'0-9₱\s\w]", js)
    if peso_ops:
        issues.append(f"₱ as operator: {peso_ops[:3]}")
    
    # Check for backtick string issues
    backtick_count = js.count('`')
    if backtick_count % 2 != 0:
        issues.append(f"ODD BACKTICK COUNT: {backtick_count}")
    
    status = "✓ OK" if not issues else "✗ ISSUES"
    print(f"Script block lines {start_line}-{end_line} ({end_line-start_line} lines): {status}")
    for issue in issues:
        print(f"  → {issue}")
    
    if issues:
        # Show first few lines of the problematic block
        block_lines = js.split('\n')
        print(f"  First 3 lines:")
        for i, l in enumerate(block_lines[:3]):
            print(f"    {start_line+i}: {l[:100]}")

print("\n=== Checking for ₱ used as ternary operator ===")
# Find ₱ that appears between ) or identifier and string/expression
for m in pattern.finditer(content):
    start_line = content[:m.start()].count('\n') + 1
    js = m.group(1)
    js_lines = js.split('\n')
    for li, line in enumerate(js_lines):
        # Look for ₱ that is NOT inside a string and NOT followed by a digit or peso-valid context
        # Pattern: identifier/closing-paren then ₱ then expression
        if '₱' in line:
            # Check if it looks like a ternary (not inside string)
            # Simple: if line has === or !== before ₱ and : after
            if re.search(r"[=!<>]=?[^₱'\"]{0,30}₱", line):
                print(f"  Possible ternary ₱ at line {start_line + li}: {line.strip()[:120]}")

print("\n=== Checking for unclosed template literals ===")
for m in pattern.finditer(content):
    start_line = content[:m.start()].count('\n') + 1
    js = m.group(1)
    # Count backticks outside strings
    in_single = False
    in_double = False
    bt_count = 0
    for i, ch in enumerate(js):
        if ch == "'" and not in_double: in_single = not in_single
        elif ch == '"' and not in_single: in_double = not in_double
        elif ch == '`' and not in_single and not in_double:
            bt_count += 1
    if bt_count % 2 != 0:
        print(f"  ODD BACKTICKS in block at line {start_line}: {bt_count} backticks")

print("\n=== Done ===")
