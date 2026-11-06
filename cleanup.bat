@echo off
echo === LabaFlow Cleanup ===
echo.

echo [1/3] Deleting flutter_mobile\build ...
if exist "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\build" (
    rmdir /s /q "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\build"
    echo DONE: build folder deleted
) else (
    echo SKIP: build folder not found
)

echo [2/3] Deleting flutter_mobile\.dart_tool ...
if exist "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\.dart_tool" (
    rmdir /s /q "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\.dart_tool"
    echo DONE: .dart_tool deleted
) else (
    echo SKIP: .dart_tool not found
)

echo [3/3] Deleting flutter_mobile\android\.gradle ...
if exist "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android\.gradle" (
    rmdir /s /q "c:\Users\chrst\Desktop\LabaFlow\flutter_mobile\android\.gradle"
    echo DONE: android\.gradle deleted
) else (
    echo SKIP: android\.gradle not found
)

echo.
echo === Cleanup complete! ===
echo Run "flutter pub get" then "flutter run" to rebuild.
pause
