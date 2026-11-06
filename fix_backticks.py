"""
Fix unclosed backtick template literals in script blocks.
These cause JS parser to treat everything after as a string — killing all functions.
"""
import re

path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()
    lines_all = content.split('\n')

pattern = re.compile(r'(<script(?![^>]*type=["\']module["\'])[^>]*>)(.*?)(</script>)', re.DOTALL)

def find_unclosed_backtick(js, start_line):
    """Find line with the unclosed backtick"""
    in_single = False
    in_double = False
    bt_stack  = []  # stack of positions where backticks opened
    
    i = 0
    line_no = start_line
    line_pos = 0  # position of start of current line
    
    while i < len(js):
        ch = js[i]
        
        if ch == '\n':
            line_no += 1
            line_pos = i + 1
        
        # Skip escaped chars
        if ch == '\\' and i + 1 < len(js):
            i += 2
            continue
        
        if ch == "'" and not in_double and not bt_stack:
            in_single = not in_single
        elif ch == '"' and not in_single and not bt_stack:
            in_double = not in_double
        elif ch == '`' and not in_single and not in_double:
            if bt_stack:
                bt_stack.pop()  # closing
            else:
                bt_stack.append((line_no, i - line_pos, js[max(0,i-20):i+40]))  # opening
        
        i += 1
    
    return bt_stack  # remaining unclosed backticks

fixes_made = 0

def fix_block(m):
    global fixes_made
    open_tag  = m.group(1)
    js        = m.group(2)
    close_tag = m.group(3)
    
    start_line = content[:m.start()].count('\n') + 1
    
    # Count raw backticks
    bt_count = js.count('`')
    if bt_count % 2 == 0:
        return m.group(0)  # Even count — OK
    
    print(f"\nBlock at line {start_line} has ODD backtick count: {bt_count}")
    
    # Find the unclosed one
    unclosed = find_unclosed_backtick(js, start_line)
    print(f"  Unclosed backticks at: {unclosed}")
    
    # Strategy: find lines containing ` in template literals within HTML strings
    # The most common cause: a template literal inside a string returned from a function
    # that has an HTML backtick-like char that got corrupted
    
    js_lines = js.split('\n')
    
    # Find and fix: look for lines with odd backtick count
    for li, line in enumerate(js_lines):
        bt_in_line = line.count('`')
        if bt_in_line % 2 != 0:
            abs_line = start_line + li
            print(f"  Odd backticks on line {abs_line}: {line.strip()[:120]}")
            
            # Common fix patterns:
            # 1. Unclosed template literal at end of line (missing closing `)
            # 2. Extra backtick in HTML string
            
            # Check if line ends with an opened template that's never closed in same line
            # Fix: look for HTML content template literals that span multiple lines incorrectly
    
    # Alternative approach: just count and balance
    # If bt_count is odd, one backtick is orphaned. Find the suspicious ones.
    suspicious = []
    for li, line in enumerate(js_lines):
        stripped = line.strip()
        if '`' in stripped:
            # Check if it's inside a // comment
            if stripped.startswith('//') or stripped.startswith('*'):
                continue
            bt_positions = [i for i, c in enumerate(stripped) if c == '`']
            suspicious.append((start_line + li, stripped[:120], len(bt_positions)))
    
    # Show last 5 suspicious lines (likely where the issue is)
    print(f"  Last 5 lines with backticks:")
    for abs_l, txt, cnt in suspicious[-5:]:
        print(f"    Line {abs_l} ({cnt} backticks): {txt}")
    
    return m.group(0)  # Don't modify yet, just report

# First pass: find and report
for m in pattern.finditer(content):
    fix_block(m)

print("\n\n=== Finding exact unclosed backtick positions ===")

# More targeted: look at the specific blocks
blocks_to_fix = [3845, 4953]

for m in pattern.finditer(content):
    start_line = content[:m.start()].count('\n') + 1
    if start_line not in blocks_to_fix:
        continue
    
    js = m.group(2)
    js_lines = js.split('\n')
    
    print(f"\nBlock starting line {start_line}:")
    
    # Find the LAST line with a backtick (most likely the unclosed one)
    last_bt_line = None
    for li, line in enumerate(js_lines):
        if '`' in line and not line.strip().startswith('//') and not line.strip().startswith('*'):
            last_bt_line = (li, start_line + li, line.strip()[:150])
    
    if last_bt_line:
        print(f"  Last backtick line: {last_bt_line[1]}: {last_bt_line[2]}")
    
    # Track balance through the block
    balance = 0
    in_single = in_double = False
    problem_lines = []
    
    for li, line in enumerate(js_lines):
        line_bt = 0
        i = 0
        while i < len(line):
            ch = line[i]
            if ch == '\\': i += 2; continue
            if ch == "'" and not in_double and balance == 0: in_single = not in_single
            elif ch == '"' and not in_single and balance == 0: in_double = not in_double
            elif ch == '`' and not in_single and not in_double:
                balance += 1 if balance == 0 else -1
                if balance < 0: balance = 0
                line_bt += 1
            i += 1
        if balance != 0 and line_bt > 0:
            problem_lines.append((li, start_line + li, line.strip()[:150], balance))
    
    print(f"  Problem lines:")
    for li, abs_l, txt, bal in problem_lines[-10:]:
        print(f"    Line {abs_l} (balance={bal}): {txt}")

print("\nDone analysis.")
