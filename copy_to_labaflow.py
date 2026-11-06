import shutil
import os
import subprocess

src_base = r'C:\Users\chrst\OneDrive\Desktop\LabaFlow\flutter_mobile'
dst_base = r'C:\LabaFlow\flutter_mobile'

copied = []
skipped = []

# Individual files
files = [
    (r'pubspec.yaml',              r'pubspec.yaml'),
    (r'lib\main.dart',             r'lib\main.dart'),
    (r'lib\router.dart',           r'lib\router.dart'),
    (r'lib\web_view_stub.dart',    r'lib\web_view_stub.dart'),
    (r'lib\web_view_web.dart',     r'lib\web_view_web.dart'),
    (r'lib\web_helper.dart',       r'lib\web_helper.dart'),
    (r'lib\web_stub.dart',         r'lib\web_stub.dart'),
    (r'assets\labaflow.html',      r'assets\labaflow.html'),
]

print("=== Copying individual files ===")
for rel_src, rel_dst in files:
    src = os.path.join(src_base, rel_src)
    dst = os.path.join(dst_base, rel_dst)
    if os.path.exists(src):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
        copied.append(rel_dst)
        print(f"  [OK]   {rel_src}")
    else:
        skipped.append(rel_src)
        print(f"  [SKIP] {rel_src}  (not found at source)")

# Directories
dirs = ['screens', 'providers', 'models', 'services', 'theme', 'widgets', 'api']

print("\n=== Copying lib subdirectories ===")
for d in dirs:
    src = os.path.join(src_base, 'lib', d)
    dst = os.path.join(dst_base, 'lib', d)
    if os.path.exists(src):
        os.makedirs(dst, exist_ok=True)
        shutil.copytree(src, dst, dirs_exist_ok=True)
        copied.append(f'lib/{d}/')
        print(f"  [OK]   lib/{d}/")
    else:
        skipped.append(f'lib/{d}/')
        print(f"  [SKIP] lib/{d}/  (not found at source)")

# Summary
print(f"\n=== Summary ===")
print(f"  Copied : {len(copied)} item(s)")
print(f"  Skipped: {len(skipped)} item(s)")
if skipped:
    for s in skipped:
        print(f"           - {s}")

# flutter pub get
print("\n=== Running flutter pub get ===")
result = subprocess.run(
    ['flutter', 'pub', 'get'],
    cwd=dst_base,
    capture_output=True,
    text=True
)
print(result.stdout)
if result.stderr:
    print(result.stderr)
print(f"Exit code: {result.returncode}")
