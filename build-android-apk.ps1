param(
  [ValidateSet("release", "debug")]
  [string]$BuildType = "release"
)

$ErrorActionPreference = "Stop"

$root       = "c:\Users\macoy\Desktop\LabaFlow"
$androidDir = "$root\android\app"
$buildDir   = "$androidDir\build\manual_apk\$BuildType"
$outApkDir  = "$androidDir\build\outputs\apk\$BuildType"

$jbrBin     = "C:\Program Files\Android\Android Studio\jbr\bin"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH   = "$jbrBin;$env:PATH"

$sdkDir     = "$env:LOCALAPPDATA\Android\Sdk"
$buildTools = "$sdkDir\build-tools\36.0.0"
$androidJar = "$sdkDir\platforms\android-36\android.jar"
if (-not (Test-Path $androidJar)) {
  $androidJar = "$sdkDir\platforms\android-37.0\android.jar"
}

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

Write-Host "[1/6] Compiling Android resources with aapt2 ($BuildType)..."
& $aapt2 compile --dir "$androidDir\src\main\res" -o "$buildDir\compiled_res\res.zip"
if ($LASTEXITCODE -ne 0) { throw "aapt2 compile failed" }

Write-Host "[2/6] Linking resources, AndroidManifest.xml, and assets..."
$linkArgs = @(
  "link",
  "-o", "$buildDir\unaligned.apk",
  "-I", $androidJar,
  "--manifest", "$androidDir\src\main\AndroidManifest.xml",
  "-A", "$androidDir\src\main\assets",
  "--java", "$buildDir\gen",
  "--min-sdk-version", "24",
  "--target-sdk-version", "35",
  "--version-code", "1",
  "--version-name", "1.0.0"
)
if ($BuildType -eq "debug") {
  $linkArgs += "--debug-mode"
}
$linkArgs += "$buildDir\compiled_res\res.zip"
& $aapt2 @linkArgs
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
$d8Args = @("--lib", $androidJar, "--min-api", "24")
if ($BuildType -eq "release") {
  $d8Args += "--release"
}
$d8Args += @("--output", "$buildDir\dex")
$d8Args += $classFiles
& $d8 @d8Args
if ($LASTEXITCODE -ne 0) { throw "d8 dexing failed" }

Write-Host "[5/6] Adding classes.dex to APK & running zipalign..."
& "$jbrBin\jar.exe" -uf "$buildDir\unaligned.apk" -C "$buildDir\dex" classes.dex
if ($LASTEXITCODE -ne 0) { throw "jar update failed" }

& $zipalign -f -p 4 "$buildDir\unaligned.apk" "$buildDir\aligned.apk"
if ($LASTEXITCODE -ne 0) { throw "zipalign failed" }

if ($BuildType -eq "release") {
  Write-Host "[6/6] Signing RELEASE APK with production keystore..."
  $propsPath = "$root\android\keystore.properties"
  if (-not (Test-Path $propsPath)) {
    throw "Missing android\keystore.properties. Copy android\keystore.properties.example and configure your release keystore."
  }
  $props = @{}
  Get-Content $propsPath | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*)$') {
      $props[$matches[1].Trim()] = $matches[2].Trim()
    }
  }
  $storeFile = $props["storeFile"]
  if (-not [System.IO.Path]::IsPathRooted($storeFile)) {
    $storeFile = Join-Path "$root\android" $storeFile
  }
  if (-not (Test-Path $storeFile)) {
    throw "Release keystore not found at: $storeFile"
  }

  $releaseApk = "$outApkDir\app-release.apk"
  & $apksigner sign `
    --ks $storeFile `
    --ks-key-alias $props["keyAlias"] `
    --ks-pass ("pass:" + $props["storePassword"]) `
    --key-pass ("pass:" + $props["keyPassword"]) `
    --v1-signing-enabled true `
    --v2-signing-enabled true `
    --v3-signing-enabled true `
    --out $releaseApk `
    "$buildDir\aligned.apk"
  if ($LASTEXITCODE -ne 0) { throw "apksigner release signing failed" }

  $verifyOut = (& $apksigner verify --print-certs --verbose $releaseApk | Out-String)
  if ($LASTEXITCODE -ne 0) { throw "apksigner verify failed" }
  if ($verifyOut -match "CN=Android Debug") {
    throw "Refusing release output: APK is still signed with Android Debug certificate!"
  }

  Copy-Item $releaseApk "$root\LabaFlow.apk" -Force
  Copy-Item $releaseApk "$root\public\LabaFlow.apk" -Force
  Write-Host $verifyOut.Trim()
  Write-Host "RELEASE_APK_SUCCESS: $root\LabaFlow.apk ($([math]::Round((Get-Item "$root\LabaFlow.apk").Length / 1KB, 1)) KB)"
} else {
  Write-Host "[6/6] Signing DEBUG APK with debug keystore..."
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
}
