path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the title and add favicon
old = content[content.find('<title>'):content.find('</title>')+8]
new_block = '''<title>LabaFlow - Lab-a-Day Laundry</title>

<!-- Favicon + App icons -->
<link rel="icon" type="image/svg+xml" href="logo.svg">
<link rel="apple-touch-icon" href="logo.svg">
<meta name="theme-color" content="#0284c7">
<meta name="application-name" content="LabaFlow">'''

content = content.replace(old, new_block)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done! Title and favicon added.")
