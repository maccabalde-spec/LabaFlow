import subprocess, os

src = r'C:\Users\chrst\OneDrive\Desktop\LabaFlow\LabaFlow.html'
lnk = r'C:\Users\chrst\OneDrive\Desktop\LabaFlow.lnk'

ps = f"""
$s=(New-Object -COM WScript.Shell).CreateShortcut('{lnk}')
$s.TargetPath='{src}'
$s.Description='LabaFlow - Lab-a-Day Laundry'
$s.Save()
Write-Host 'Shortcut updated'
"""
r = subprocess.run(['powershell','-NoProfile','-Command',ps], capture_output=True, text=True)
size = os.path.getsize(src)
print(f'LabaFlow.html size: {size:,} bytes')
print(r.stdout.strip() or r.stderr.strip())
