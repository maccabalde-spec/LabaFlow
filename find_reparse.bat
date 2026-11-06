@echo off
for /r "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android" %%f in (*) do (
    fsutil reparsepoint query "%%f" 2>nul >nul && echo REPARSE: %%f
)
echo Done scanning.
