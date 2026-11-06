@echo off
echo === LabaFlow Project Sizes ===
echo.
echo [flutter_mobile\build]
powershell -command "(Get-ChildItem 'c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\build' -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB" 2>nul
echo MB
echo.
echo [flutter_mobile\.dart_tool]
powershell -command "(Get-ChildItem 'c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\.dart_tool' -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB" 2>nul
echo MB
echo.
echo [.gradle cache]
powershell -command "(Get-ChildItem 'c:\Users\chrst\.gradle' -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB" 2>nul
echo MB
echo.
echo [Android SDK build-tools+emulator]
powershell -command "(Get-ChildItem 'c:\Users\chrst\AppData\Local\Android\sdk' -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB" 2>nul
echo MB
echo.
echo Done.
