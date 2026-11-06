"""
Find and fix the EXACT unclosed backtick in the two problem script blocks.
Strategy: scan character by character tracking state properly.
"""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = re.compile(r'(<script(?![^>]*type=["\']module["\'])[^>]*>)(.*?)(</script>)', re.DOTALL)

def scan_js(js, block_start_line):
    """
    Properly scan JS tracking strings.
    Returns list of (line, col, type) for unmatched backticks.
    """
    i = 0
    n = len(js)
    line = block_start_line
    line_start = 0
    
    # Stack: each entry is ('bt', open_line, open_col)
    bt_stack = []
    in_single = False
    in_double = False
    depth = 0  # ${...} depth inside template
    
    events = []  # track all backtick open/close events
    
    while i < n:
        ch = js[i]
        
        if ch == '\n':
            line += 1
            line_start = i + 1
            i += 1
            continue
        
        # Escape sequence
        if ch == '\\' and i + 1 < n:
            i += 2
            continue
        
        col = i - line_start
        
        if not in_double and not bt_stack and ch == "'":
            in_single = not in_single
            i += 1
            continue
            
        if not in_single and not bt_stack and ch == '"':
            in_double = not in_double
            i += 1
            continue
        
        if not in_single and not in_double:
            if ch == '`':
                if bt_stack:
                    # Close backtick
                    opened = bt_stack.pop()
                    events.append(('close', line, col, opened))
                else:
                    # Open backtick
                    bt_stack.append((line, col))
                    events.append(('open', line, col, js[i:i+50]))
                i += 1
                continue
            
            # Inside template literal: track ${} for nested expressions
            if bt_stack:
                if ch == '$' and i+1 < n and js[i+1] == '{':
                    depth += 1
                elif ch == '}' and depth > 0:
                    depth -= 1
        
        i += 1
    
    return bt_stack, events  # bt_stack = unclosed backticks

blocks_to_check = [3845, 4953]

for m in pattern.finditer(content):
    start_line = content[:m.start()].count('\n') + 1
    if start_line not in blocks_to_check:
        continue
    
    js = m.group(2)
    bt_count = js.count('`')
    print(f"\n=== Block at line {start_line} ({bt_count} backticks) ===")
    
    unclosed, events = scan_js(js, start_line)
    
    if unclosed:
        print(f"UNCLOSED BACKTICKS:")
        for open_line, open_col in unclosed:
            # Get the actual line content
            all_lines = content.split('\n')
            if open_line - 1 < len(all_lines):
                line_content = all_lines[open_line - 1]
                print(f"  Line {open_line}, col {open_col}: {line_content.strip()[:150]}")
    else:
        print("  All backticks balanced (false alarm from simpler check)")
    
    # Show last 10 events to understand the flow
    print(f"\nLast 5 backtick events:")
    for ev in events[-5:]:
        if ev[0] == 'open':
            print(f"  OPEN  line {ev[1]}: {ev[3][:80]}")
        else:
            print(f"  CLOSE line {ev[1]}")

print("\n=== Done ===")
