@echo off
echo Checking kotlin folders...
fsutil reparsepoint query "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android\app\src\main\kotlin\com\labaday\labaflow_mobile\MainActivity.kt" 2>nul >nul && echo REPARSE: labaflow_mobile\MainActivity.kt || echo OK: labaflow_mobile\MainActivity.kt
fsutil reparsepoint query "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android\app\src\main\kotlin\com\labaday\labaflow_app\MainActivity.kt" 2>nul >nul && echo REPARSE: labaflow_app\MainActivity.kt || echo OK: labaflow_app\MainActivity.kt
