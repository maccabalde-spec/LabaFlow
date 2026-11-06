path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Remove all ════ marked CSS blocks (dashboard theme injections)
removed = 0
while True:
    idx = content.find('/* ════')
    if idx == -1:
        break
    # Find end: next triple newline
    end = content.find('\n\n\n', idx)
    if end == -1 or end - idx > 20000:
        end = idx + 100
    removed += 1
    content = content[:idx] + content[end+3:]

print(f"Removed {removed} injected CSS blocks")

# Ensure original launchApp is present (should be in this version)
has_launch = 'async function launchApp()' in content
print(f"launchApp present: {has_launch}")

# Remove any _waitForDB if present
if '_waitForDB' in content:
    # Remove the function
    wait_start = content.find('/* Wait for Firebase')
    saved_start = content.find('const savedCU=sessionStorage')
    if wait_start != -1 and saved_start > wait_start:
        content = content[:wait_start] + content[saved_start:]
    # Fix auto-login
    content = re.sub(
        r'if\(savedCU\)\{[^}]{0,200}_waitForDB[^}]{0,200}\}',
        "if(savedCU){try{CU=JSON.parse(savedCU);launchApp();}catch(e){}}",
        content, flags=re.DOTALL
    )
    print("Removed _waitForDB")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Final size: {len(content)}")
print("Done!")
