@echo off
fsutil reparsepoint query "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android\app\src\main\AndroidManifest.xml" 2>nul >nul && echo REPARSE: AndroidManifest.xml || echo OK: AndroidManifest.xml is a normal file
fsutil reparsepoint query "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android\app\build.gradle.kts" 2>nul >nul && echo REPARSE: build.gradle.kts || echo OK: build.gradle.kts is a normal file
fsutil reparsepoint query "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android\settings.gradle.kts" 2>nul >nul && echo REPARSE: settings.gradle.kts || echo OK: settings.gradle.kts is a normal file
