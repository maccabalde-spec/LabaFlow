$ErrorActionPreference = "Stop"

$root       = "c:\Users\macoy\Desktop\LabaFlow"
$androidDir = "$root\android\app"
$buildDir   = "$androidDir\build\manual_apk"
$outApkDir  = "$androidDir\build\outputs\apk\debug"

$jbrBin     = "C:\Program Files\Android\Android Studio\jbr\bin"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH   = "$jbrBin;$env:PATH"

$sdkDir     = "$env:LOCALAPPDATA\Android\Sdk"
$buildTools = "$sdkDir\build-tools\36.0.0"
$androidJar = "$sdkDir\platforms\android-37.0\android.jar"

$aapt2      = "$buildTools\aapt2.exe"
$d8         = "$buildTools\d8.bat"
$zipalign   = "$buildTools\zipalign.exe"
$apksigner  = "$buildTools\apksigner.bat"
$javac      = "$jbrBin\javac.exe"
$keytool    = "$jbrBin\keytool.exe"

if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory -Path "$buildDir\compiled_res" -Force | Out-Null
New-Item -ItemType Directory -Path "$buildDir\gen" -Force | Out-Null
New-Item -ItemType Directory -Path "$buildDir\classes" -Force | Out-Null
New-Item -ItemType Directory -Path "$buildDir\dex" -Force | Out-Null
New-Item -ItemType Directory -Path $outApkDir -Force | Out-Null

Write-Host "[1/6] Compiling Android resources with aapt2..."
& $aapt2 compile --dir "$androidDir\src\main\res" -o "$buildDir\compiled_res\res.zip"
if ($LASTEXITCODE -ne 0) { throw "aapt2 compile failed" }

Write-Host "[2/6] Linking resources, AndroidManifest.xml, and assets..."
& $aapt2 link `
  -o "$buildDir\unaligned.apk" `
  -I $androidJar `
  --manifest "$androidDir\src\main\AndroidManifest.xml" `
  -A "$androidDir\src\main\assets" `
  --java "$buildDir\gen" `
  --min-sdk-version 24 `
  --target-sdk-version 35 `
  --version-code 1 `
  --version-name "1.0.0" `
  "$buildDir\compiled_res\res.zip"
if ($LASTEXITCODE -ne 0) { throw "aapt2 link failed" }

Write-Host "[3/6] Compiling Java sources (MainActivity.java + R.java)..."
$javaFiles = @(
  "$androidDir\src\main\java\com\labaday\labaflow\MainActivity.java",
  "$buildDir\gen\com\labaday\labaflow\R.java"
)
& $javac --release 11 -encoding UTF-8 -cp $androidJar -d "$buildDir\classes" $javaFiles
if ($LASTEXITCODE -ne 0) { throw "javac compilation failed" }

Write-Host "[4/6] Converting .class bytecode to Dalvik executable (classes.dex) with d8..."
$classFiles = Get-ChildItem -Path "$buildDir\classes" -Filter "*.class" -Recurse | ForEach-Object { $_.FullName }
& $d8 --lib $androidJar --min-api 24 --output "$buildDir\dex" $classFiles
if ($LASTEXITCODE -ne 0) { throw "d8 dexing failed" }

Write-Host "[5/6] Adding classes.dex to APK & running zipalign..."
& "$jbrBin\jar.exe" -uf "$buildDir\unaligned.apk" -C "$buildDir\dex" classes.dex
if ($LASTEXITCODE -ne 0) { throw "jar update failed" }

& $zipalign -f -p 4 "$buildDir\unaligned.apk" "$buildDir\aligned.apk"
if ($LASTEXITCODE -ne 0) { throw "zipalign failed" }

Write-Host "[6/6] Signing APK with debug keystore..."
$ksPath = "$root\android\debug.keystore"
if (-not (Test-Path $ksPath)) {
  $ErrorActionPreference = "Continue"
  & $keytool -genkeypair -keystore $ksPath -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" *> $null
  $ErrorActionPreference = "Stop"
}

$finalApk1 = "$root\LabaFlow-debug.apk"
$finalApk2 = "$outApkDir\app-debug.apk"

& $apksigner sign --ks $ksPath --ks-pass pass:android --key-pass pass:android --out $finalApk1 "$buildDir\aligned.apk"
if ($LASTEXITCODE -ne 0) { throw "apksigner failed" }

Copy-Item $finalApk1 $finalApk2 -Force
Write-Host "APK_BUILD_SUCCESS: $finalApk1 ($([math]::Round((Get-Item $finalApk1).Length / 1KB, 1)) KB)"
