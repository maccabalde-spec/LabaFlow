$ErrorActionPreference = "Continue"
$root     = "c:\Users\macoy\Desktop\LabaFlow"
$sdkDir   = "$env:LOCALAPPDATA\Android\Sdk"
$adb      = "$sdkDir\platform-tools\adb.exe"
$emulator = "$sdkDir\emulator\emulator.exe"
$studio   = "C:\Program Files\Android\Android Studio\bin\studio64.exe"
$apkPath  = "$root\LabaFlow-debug.apk"

if (-not (Test-Path $apkPath)) {
  powershell -ExecutionPolicy Bypass -File "$root\build-android-apk.ps1"
}

& $adb start-server | Out-Null
$devices = & $adb devices | Select-String -Pattern "\t(device|emulator)"

if (-not $devices) {
  $avds = & $emulator -list-avds
  $avd = ($avds | Select-Object -First 1)
  if ($avd) {
    Write-Host "Starting Android Studio Emulator: $avd ..."
    Start-Process -FilePath $emulator -ArgumentList "-avd", $avd, "-no-snapshot-load" -WindowStyle Normal
  } else {
    Write-Warning "No Android device or AVD found. Please connect your phone via USB Debugging or create an AVD in Android Studio."
    exit 1
  }
}

Write-Host "Waiting for Android device to come online..."
& $adb wait-for-device
for ($i = 0; $i -lt 60; $i++) {
  $boot = (& $adb shell getprop sys.boot_completed 2>$null)
  if ($boot -and $boot.Trim() -eq "1") { break }
  Start-Sleep -Seconds 2
}

Write-Host "Installing LabaFlow APK ($apkPath)..."
$installOut = (& $adb install -r $apkPath 2>&1 | Out-String)
if ($installOut -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE|Failure") {
  Write-Host "Removing previous signature & performing clean install..."
  & $adb uninstall com.labaday.labaflow 2>$null | Out-Null
  & $adb install -r $apkPath
} else {
  Write-Host $installOut.Trim()
}

Write-Host "Granting notification permission & launching LabaFlow..."
& $adb shell pm grant com.labaday.labaflow android.permission.POST_NOTIFICATIONS 2>$null
& $adb shell am start -n com.labaday.labaflow/.MainActivity
Write-Host "DEPLOY_SUCCESS: LabaFlow is now running on your Android device!"
