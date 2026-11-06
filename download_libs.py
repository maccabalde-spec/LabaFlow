import urllib.request

libs = {
    'sweetalert2': 'https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js',
    'chartjs': 'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js',
    'qrcodejs': 'https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js',
}

contents = {}
for name, url in libs.items():
    print(f'Downloading {name}...')
    with urllib.request.urlopen(url) as r:
        contents[name] = r.read().decode('utf-8', errors='replace')
    print(f'  Done: {len(contents[name])} chars')

# Read HTML
path = 'C:/LabaFlow/flutter_mobile/assets/labaflow.html'
with open(path, 'r', encoding='utf-8') as f:
    html = f.read()

# Replace CDN links with inline scripts
html = html.replace(
    '<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>',
    '<script>' + contents['sweetalert2'] + '</script>'
)
html = html.replace(
    '<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>',
    '<script>' + contents['chartjs'] + '</script>'
)
html = html.replace(
    '<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>',
    '<script>' + contents['qrcodejs'] + '</script>'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(html)

print('\nDONE - All libraries bundled inline. App will now load fast offline!')
