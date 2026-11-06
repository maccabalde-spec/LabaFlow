# Create LabaFlow desktop shortcut with custom icon
$WshShell = New-Object -ComObject WScript.Shell

# Remove old .url shortcut if exists
$oldUrl = "$env:USERPROFILE\Desktop\LabaFlow Web.url"
if (Test-Path $oldUrl) { Remove-Item $oldUrl -Force }

# Create .lnk shortcut pointing to Chrome with the URL
$shortcutPath = "$env:USERPROFILE\Desktop\LabaFlow.lnk"

$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath      = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$Shortcut.Arguments       = "--app=https://labaflow-71e13.web.app"
$Shortcut.WorkingDirectory= "C:\Program Files\Google\Chrome\Application"
$Shortcut.IconLocation    = "C:\Users\chrst\Desktop\LabaFlow\public\icon-192.png,0"
$Shortcut.WindowStyle     = 1
$Shortcut.Description     = "LabaFlow - Lab-a-Day Laundry"
$Shortcut.Save()

Write-Host "Shortcut created at: $shortcutPath"
