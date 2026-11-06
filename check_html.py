content = open(r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html', encoding='utf-8').read()
opens = content.count('<style')
closes = content.count('</style>')
print(f'style opens: {opens}, closes: {closes}')
script_o = content.count('<script')
script_c = content.count('</script>')
print(f'script opens: {script_o}, closes: {script_c}')
print(f'body tag: {"<body>" in content or "body" in content}')
print(f'File size: {len(content)}')

# Check if style is unclosed
idx = content.find('<style')
end = content.find('</style>', idx)
print(f'First style: open={idx}, close={end}')

# Find all style tags
import re
styles = [(m.start(), m.group()) for m in re.finditer(r'</?style[^>]*>', content)]
print(f'All style tags ({len(styles)}):')
for pos, tag in styles:
    line = content[:pos].count('\n') + 1
    print(f'  line {line}: {tag}')
