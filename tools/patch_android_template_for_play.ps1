$ErrorActionPreference = 'Stop'

$project = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$config = Join-Path $project 'android\build\config.gradle'
$buildIgnore = Join-Path $project 'android\build\.gdignore'
$assetPacksIgnore = Join-Path $project 'android\build\assetPacks\.gdignore'

if (-not (Test-Path -LiteralPath $config)) {
  throw "Missing Android Gradle config. Install or expand the Godot Android build template first: $config"
}

$text = Get-Content -LiteralPath $config -Raw
$text = $text -replace 'compileSdk\s*:\s*\d+', 'compileSdk         : 35'
$text = $text -replace 'targetSdk\s*:\s*\d+', 'targetSdk          : 35'
$text = $text -replace "buildTools\s*:\s*'[^']+'", "buildTools         : '35.0.0'"
$text = $text -replace 'return Integer\.parseInt\(targetSdkVersion\)', 'return Math.max(Integer.parseInt(targetSdkVersion), versions.targetSdk)'
Set-Content -LiteralPath $config -Value $text -NoNewline

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $buildIgnore) | Out-Null
New-Item -ItemType File -Force -Path $buildIgnore | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $assetPacksIgnore) | Out-Null
New-Item -ItemType File -Force -Path $assetPacksIgnore | Out-Null

$resImportFiles = Get-ChildItem -LiteralPath (Join-Path $project 'android\build\res') -Recurse -Force -Filter '*.import' -ErrorAction SilentlyContinue
$resImportCount = ($resImportFiles | Measure-Object).Count
$resImportFiles | Remove-Item -Force

$assetPackAssets = Join-Path $project 'android\build\assetPacks\installTime\src\main\assets'
if (Test-Path -LiteralPath $assetPackAssets) {
  Remove-Item -LiteralPath $assetPackAssets -Recurse -Force
}

Write-Host "ANDROID_TEMPLATE_PLAY_PATCH_PASS target_sdk=35 removed_res_import=$resImportCount"
