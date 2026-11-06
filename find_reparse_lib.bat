@echo off
for /r "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\lib" %%f in (*) do (
    fsutil reparsepoint query "%%f" 2>nul >nul && echo REPARSE: %%f
)
for /r "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\assets" %%f in (*) do (
    fsutil reparsepoint query "%%f" 2>nul >nul && echo REPARSE: %%f
)
echo Done scanning lib and assets.
