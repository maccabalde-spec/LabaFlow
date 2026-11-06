@echo off
echo ===================================================
echo   LabaFlow Auto-Sync and Auto-Deploy to GitHub
echo ===================================================
SET PATH=C:\Users\macoy\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd;C:\Program Files\GitHub CLI;%PATH%

cd /d "%~dp0"

echo [1/3] Syncing Web and Mobile HTML/JS bundles...
copy /Y "flutter_mobile\web\labaflow.html" "index.html" >nul
copy /Y "flutter_mobile\web\labaflow.html" "LabaFlow.html" >nul
copy /Y "flutter_mobile\web\labaflow.html" "flutter_mobile\assets\labaflow.html" >nul
if exist "flutter_mobile\build\web" copy /Y "flutter_mobile\web\labaflow.html" "flutter_mobile\build\web\labaflow.html" >nul

copy /Y "flutter_mobile\web\supabase-web-auth.js" "supabase-web-auth.js" >nul
copy /Y "flutter_mobile\web\supabase-web-auth.js" "flutter_mobile\assets\supabase-web-auth.js" >nul
if exist "flutter_mobile\build\web" copy /Y "flutter_mobile\web\supabase-web-auth.js" "flutter_mobile\build\web\supabase-web-auth.js" >nul

echo [2/3] Committing changes...
git add .
git commit -m "chore: auto-sync and deploy update"

echo [3/3] Pushing to GitHub (Auto-Deploys Live Website)...
git push origin main

echo.
echo Done! Live URL: https://maccabalde-spec.github.io/LabaFlow/
pause
