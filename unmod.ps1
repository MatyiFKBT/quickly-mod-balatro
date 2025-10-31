# This script attempts to "unmod" Balatro by removing
# - The %APPDATA%\Balatro\Mods directory (backed up unless -Force)
# - Lovely / Steamodded related injector files from the game directory (pattern based)
# Optionally triggers Steam's built-in file validation if -Validate is passed.
# (Uses steam://validate/2379780 URI; no completion signal is captured.)

param(
  [switch]$Force,
  [switch]$NoBackup,
  [switch]$Debug,
  [switch]$Validate
)

function Debug-Write($m){ if($Debug){ Write-Host $m -ForegroundColor DarkGray } }

# Discover Steam install path (same logic as setup.ps1)
$notfound = $true
$steaminstallpath = (Get-ItemProperty -Path HKCU:\SOFTWARE\Valve\Steam -ErrorVariable 'notfound' -ErrorAction Ignore).SteamPath
if ($notfound) { Write-Host "Steam install path not found in registry. Aborting." -ForegroundColor Red; exit 1 }

# Locate Balatro install folder by scanning libraryfolders.vdf for app id 2379780
$applist = Get-Content "$steaminstallpath/steamapps/libraryfolders.vdf" -Raw
$regexPattern = '(?s)"path"\s+"([^"]+)"\s+[^}]+?"apps"\s*\{[^}]+?"2379780"\s+'
$match = [regex]::Match($applist, $regexPattern)
if(-not $match.Success){ Write-Host "Could not locate Balatro install (app 2379780)." -ForegroundColor Red; exit 1 }
$gamePath = ($match.Groups[1].Value -replace '\\\\','\') + "\SteamApps\common\Balatro"
if(-not (Test-Path $gamePath)){ Write-Host "Resolved game path '$gamePath' not found." -ForegroundColor Red; exit 1 }

Write-Host "Game directory: $gamePath" -ForegroundColor Cyan

# Mods directory in AppData
$modsPath = "$env:APPDATA/Balatro/Mods"

# Build list of candidate injector / mod framework files in game directory
# We use patterns to avoid accidentally removing unrelated files.
$candidatePatterns = @(
  'lovely*',
  'Lovely*',
  'steamodded*',
  'Steamodded*'
)
$candidateFiles = @()
foreach($pat in $candidatePatterns){
  $candidateFiles += Get-ChildItem -LiteralPath $gamePath -Filter $pat -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer }
}
$candidateFiles = $candidateFiles | Select-Object -Unique

if($candidateFiles.Count -eq 0){
  Debug-Write "No injector candidates found via patterns."
} else {
  Write-Host "Found possible injector/framework files:" -ForegroundColor Yellow
  $candidateFiles | ForEach-Object { Write-Host "  $_" }
}

$actions = @()
if(Test-Path $modsPath){ $actions += "Remove mods directory: $modsPath" }
if($candidateFiles.Count -gt 0){ $actions += "Delete injector/framework files in game directory" }
if($actions.Count -eq 0){ Write-Host "No mod-related artifacts detected. Nothing to do." -ForegroundColor Green; exit 0 }

Write-Host "Planned actions:" -ForegroundColor Cyan
$actions | ForEach-Object { Write-Host " - $_" }

if(-not $Force){
  $choice = Read-Host "Proceed with these actions? (y/N)"
  if($choice.ToLower() -ne 'y'){ Write-Host "Aborted."; exit 0 }
}

# Backup mods directory unless suppressed
if(Test-Path $modsPath){
  if(-not $NoBackup){
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupDir = "$modsPath`_backup_$timestamp"
    try {
      Write-Host "Backing up Mods directory to $backupDir ..." -NoNewline
      Copy-Item $modsPath $backupDir -Recurse -Force
      Write-Host " done." -ForegroundColor Green
    } catch {
      Write-Host " backup failed: $($_.Exception.Message)" -ForegroundColor Red
      if(-not $Force){ Write-Host "Aborting to avoid data loss." -ForegroundColor Yellow; exit 1 }
    }
  } else {
    Write-Host "Skipping backup due to -NoBackup" -ForegroundColor Yellow
  }
  Write-Host "Removing Mods directory..." -NoNewline
  Remove-Item $modsPath -Recurse -Force
  Write-Host " done." -ForegroundColor Green
}

if($candidateFiles.Count -gt 0){
  Write-Host "Removing injector/framework files..." -NoNewline
  foreach($f in $candidateFiles){
    try { Remove-Item $f.FullName -Force } catch { Write-Host "\nFailed to remove $($f.FullName): $($_.Exception.Message)" -ForegroundColor Red }
  }
  Write-Host " done." -ForegroundColor Green
}

Write-Host "Unmod operation complete." -ForegroundColor Green
if($Validate){
  Write-Host "Launching Steam validation (steam://validate/2379780) ..." -ForegroundColor Cyan
  try { Start-Process "steam://validate/2379780" } catch { Write-Host "Failed to launch Steam validation: $($_.Exception.Message)" -ForegroundColor Red }
} else {
  Write-Host "(Pass -Validate to automatically open Steam file verification.)" -ForegroundColor DarkGray
}
