@echo off
echo Scanning entire flutter_mobile\android\app\src for reparse points...
echo.
set FOUND=0
for /r "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android\app\src" %%f in (*) do (
    fsutil reparsepoint query "%%f" 2>nul >nul && echo REPARSE: %%f && set FOUND=1
)
if %FOUND%==0 echo ALL CLEAR - No reparse points found!
echo.
echo Done.
