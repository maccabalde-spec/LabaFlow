path = r'c:\Users\chrst\Desktop\LabaFlow\LabaFlow.html'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = '''<!-- Favicon + App icons -->
<link rel="icon" type="image/svg+xml" href="logo.svg">
<link rel="apple-touch-icon" href="logo.svg">
<meta name="theme-color" content="#0284c7">
<meta name="application-name" content="LabaFlow">'''

new = '''<!-- Favicon + PWA icons -->
<link rel="icon" type="image/png" sizes="32x32" href="favicon-32.png">
<link rel="icon" type="image/png" sizes="16x16" href="favicon-16.png">
<link rel="apple-touch-icon" sizes="192x192" href="icon-192.png">
<meta name="theme-color" content="#0284c7">
<meta name="application-name" content="LabaFlow">
<link rel="manifest" href="manifest.json">'''

content = content.replace(old, new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
