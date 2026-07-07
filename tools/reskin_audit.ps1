param(
  [Parameter(Mandatory = $true)]
  [string]$GameRoot,

  [switch]$FailOnWarnings,
  [switch]$Json
)

$ErrorActionPreference = "Stop"

$resolvedRoot = (Resolve-Path -LiteralPath $GameRoot).Path
$issues = New-Object System.Collections.Generic.List[object]

function Add-Issue {
  param(
    [string]$Severity,
    [string]$Code,
    [string]$Message,
    [string]$Path = ""
  )
  $issues.Add([pscustomobject]@{
    severity = $Severity
    code = $Code
    message = $Message
    path = $Path
  })
}

function Test-AnyFile {
  param([string[]]$Patterns)
  $normalizedPatterns = $Patterns | ForEach-Object { $_.Replace('\', '/') }
  foreach ($pattern in $Patterns) {
    $match = Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object {
        $relative = $_.FullName.Substring($resolvedRoot.Length).TrimStart('\', '/').Replace('\', '/')
        foreach ($normalizedPattern in $normalizedPatterns) {
          if ($relative -like $normalizedPattern) { return $true }
        }
        return $false
      } |
      Select-Object -First 1
    if ($match) { return $match.FullName }
  }
  return ""
}

function Read-TextFiles {
  param([string[]]$Extensions)
  Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
      $full = $_.FullName
      $ext = $_.Extension.ToLowerInvariant()
      $Extensions -contains $ext -and
      $full -notmatch '\\\.godot\\' -and
      $full -notmatch '\\\.import\\' -and
      $full -notmatch '\\addons\\shinokute_game_core\\'
    }
}

$checklist = Test-AnyFile @("docs/reskin_checklist.md", "docs/*reskin*checklist*.md")
if (-not $checklist) {
  Add-Issue "error" "MissingReskinChecklist" "Copy docs/reskin_checklist_template.md into the game repo before reskin edits."
}

$screenshotChecklist = Test-AnyFile @("docs/screenshot_verification_checklist.md", "docs/*screenshot*checklist*.md")
if (-not $screenshotChecklist) {
  Add-Issue "error" "ScreenshotEvidence" "Missing screenshot verification checklist for desktop/mobile text-fit review."
}

$assetManifest = Test-AnyFile @("docs/asset_manifest.md", "docs/*asset*manifest*.md")
if (-not $assetManifest) {
  Add-Issue "error" "AssetManifest" "Missing game-local asset manifest for Block Kit, owner rect, and In-game Size evidence."
} else {
  $assetManifestContent = Get-Content -LiteralPath $assetManifest -Raw
  foreach ($required in @("Block Kit", "Owner Rect", "In-game Size")) {
    if ($assetManifestContent -notmatch [regex]::Escape($required)) {
      Add-Issue "error" "AssetManifest" "Asset manifest missing $required." $assetManifest
    }
  }
}

$coreConfig = Test-AnyFile @("Resources/Data/*game_core_config*.tres", "Resources/Data/*GameCoreConfig*.tres")
if (-not $coreConfig) {
  Add-Issue "error" "MissingGameCoreConfig" "Missing game-owned GameCoreConfig resource."
} else {
  $content = Get-Content -LiteralPath $coreConfig -Raw
  if ($content -notmatch "GameCoreConfig") {
    Add-Issue "warning" "GameCoreConfig" "Config file does not mention GameCoreConfig." $coreConfig
  }
}

$themeConfig = Test-AnyFile @("Resources/Data/*theme_config*.tres", "Resources/Data/*ThemeConfig*.tres")
if (-not $themeConfig) {
  Add-Issue "error" "MissingThemeConfig" "Missing game-owned ShinokuteThemeConfig resource."
} else {
  $content = Get-Content -LiteralPath $themeConfig -Raw
  if ($content -notmatch "ShinokuteThemeConfig") {
    Add-Issue "warning" "ShinokuteThemeConfig" "Theme config file does not mention ShinokuteThemeConfig." $themeConfig
  }
}

$rulesFile = Test-AnyFile @("Scripts/*Rules.gd", "Scripts/*rules.gd")
if (-not $rulesFile) {
  Add-Issue "error" "MissingRulesAdapter" "Missing game rules adapter script."
} else {
  $content = Get-Content -LiteralPath $rulesFile -Raw
  if ($content -notmatch "GameRulesAdapter") {
    Add-Issue "error" "GameRulesAdapter" "Rules script must extend or wrap GameRulesAdapter." $rulesFile
  }
  foreach ($method in @("start_run", "can_make_move", "apply_move", "is_game_over", "get_result")) {
    if ($content -notmatch "func\s+$method\s*\(") {
      Add-Issue "error" "GameRulesAdapter" "Rules adapter missing $method." $rulesFile
    }
  }
}

$contractTest = Test-AnyFile @("Tests/test_shinokute_reskin_contract.gd", "Tests/*reskin*contract*.gd")
if (-not $contractTest) {
  Add-Issue "error" "MissingContractTest" "Missing game-local Shinokute reskin contract test."
}

$textFitEvidence = $false
if ($checklist) {
  $checklistContent = Get-Content -LiteralPath $checklist -Raw
  $textFitEvidence = $checklistContent -match "All labels fit inside their owner regions" -and
    $checklistContent -match "Screen still reads as a game screen"
}
if (-not $textFitEvidence) {
  Add-Issue "error" "TextFitEvidence" "Checklist must include filled Text Fit And Game Context evidence."
}

$forbiddenManagers = @(
  "SaveManager",
  "LeaderboardManager",
  "AdManager",
  "AudioManager",
  "ThemeManager"
)

$hardcodedPatterns = @(
  @{ code = "HardcodedValueAudit"; regex = 'res://(?!addons/shinokute_game_core)'; message = "Hardcoded res:// path outside Shinokute core. Use SSOT key." },
  @{ code = "HardcodedValueAudit"; regex = 'Color\("#?[0-9A-Fa-f]{6,8}"\)'; message = "Hardcoded color literal. Use theme token." },
  @{ code = "HardcodedValueAudit"; regex = '\.text\s*=\s*"[^"]{2,}"'; message = "Hardcoded UI text. Use localization key." },
  @{ code = "HardcodedValueAudit"; regex = 'change_scene_to_file\("res://'; message = "Hardcoded scene route. Use scene_router." }
)

foreach ($file in Read-TextFiles @(".gd", ".tscn", ".tres")) {
  $content = Get-Content -LiteralPath $file.FullName -Raw
  foreach ($manager in $forbiddenManagers) {
    if ($content -match "\b$manager\b") {
      Add-Issue "warning" "CopiedManagerAudit" "Possible copied legacy manager reference: $manager." $file.FullName
    }
  }
  foreach ($pattern in $hardcodedPatterns) {
    if ($content -match $pattern.regex) {
      Add-Issue "warning" $pattern.code $pattern.message $file.FullName
    }
  }
}

if ($Json) {
  [pscustomobject]@{
    gameRoot = $resolvedRoot
    issueCount = $issues.Count
    issues = $issues
  } | ConvertTo-Json -Depth 5
} else {
  Write-Output "Shinokute Reskin Audit"
  Write-Output "GameRoot: $resolvedRoot"
  if ($issues.Count -eq 0) {
    Write-Output "PASS: no issues found"
  } else {
    foreach ($issue in $issues) {
      $location = if ($issue.path) { " [$($issue.path)]" } else { "" }
      Write-Output "$($issue.severity.ToUpperInvariant()) $($issue.code): $($issue.message)$location"
    }
  }
}

$errorCount = ($issues | Where-Object { $_.severity -eq "error" }).Count
$warningCount = ($issues | Where-Object { $_.severity -eq "warning" }).Count
if ($errorCount -gt 0 -or ($FailOnWarnings -and $warningCount -gt 0)) {
  exit 1
}
exit 0
