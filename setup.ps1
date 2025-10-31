# This script is used to mod Balatro.
# It will download the required files from GitHub and install them in the correct location.
Write-Host @"

██████   █████  ██       █████  ████████ ██████   ██████              
██   ██ ██   ██ ██      ██   ██    ██    ██   ██ ██    ██             
██████  ███████ ██      ███████    ██    ██████  ██    ██             
██   ██ ██   ██ ██      ██   ██    ██    ██   ██ ██    ██             
██████  ██   ██ ███████ ██   ██    ██    ██   ██  ██████              
                                                                      
            ███    ███  ██████  ██████  ██████  ██ ███    ██  ██████  
            ████  ████ ██    ██ ██   ██ ██   ██ ██ ████   ██ ██       
█████ █████ ██ ████ ██ ██    ██ ██   ██ ██   ██ ██ ██ ██  ██ ██   ███ 
            ██  ██  ██ ██    ██ ██   ██ ██   ██ ██ ██  ██ ██ ██    ██ 
            ██      ██  ██████  ██████  ██████  ██ ██   ████  ██████  
                                                                      
"@                                                                      
## PART 0 - Check for installed stuff ##
# Check if winget is installed, if not, install it using the Windows Package Manager
$wingetPath = Get-Command winget -ErrorAction SilentlyContinue
if ($null -eq $wingetPath)
{
  $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
  $URL = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json |
    Select-Object -ExpandProperty "assets" |
    Where-Object "browser_download_url" -Match '.msixbundle' |
    Select-Object -ExpandProperty "browser_download_url"
  # download
  Invoke-WebRequest -Uri $URL -OutFile "Setup.msix" -UseBasicParsing
  # install
  Add-AppxPackage -Path "Setup.msix"
  # delete file
  Remove-Item "Setup.msix"
}

# Check if git is installed, if not, install it using winget (Windows Package Manager)
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if ($null -eq $gitPath)
{
  winget install -e --id Git.Git
}

$balatroID = "2379780"
$debug = $false

# Check if script is called with --debug or -d
if ($args -contains "--debug" -or $args -contains "-d") {
  $debug = $true
}

function Debug-Write($message) {
  if ($debug) {
    Write-Host $message
  }
}

$notfound = $true
$steaminstallpath = (Get-ItemProperty -Path HKCU:\SOFTWARE\Valve\Steam -ErrorVariable 'notfound' -ErrorAction Ignore).SteamPath
if ($notfound) {
  Write-Host "Steam install path not found in registry... if you have Steam installed, but still see this message, please open an issue on GitHub."
}
$applist = Get-Content "$steaminstallpath\steamapps\libraryfolders.vdf" -Raw
$regexPattern = '(?s)"path"\s+"([^"]+)"\s+[^}]+?"apps"\s*\{[^}]+?"2379780"\s+'
$match = [regex]::Match($applist, $regexPattern)

if ($match.Success) {
  $gamePath = $match.Groups[1].Value -replace '\\\\', '\'
  $gamePath = "$gamePath\SteamApps\common\Balatro"
} else {
  Write-Host "Balatro not found in the file. Is Balatro installed? Please check, and if it is installed, feel free to open an issue on GitHub."
  exit
}
Debug-Write "Balatro is installed at: ${gamePath}"

## PART 1 - Setup Lovely and Steamodded ##
## Reference: https://github.com/Steamopollys/Steamodded/wiki/01.-Getting-started

$lovelyURL = "https://github.com/ethangreen-dev/lovely-injector/releases/latest/download/lovely-x86_64-pc-windows-msvc.zip"

# Download the lovely injector to game directory and unzip it
Write-Host "Downloading lovely injector to $gamePath... " -NoNewline
Invoke-WebRequest -Uri $lovelyURL -OutFile "$gamePath\lovely.zip"
Write-Host "done."

Write-Host "Unzipping lovely injector... " -NoNewline
Expand-Archive -Path "$gamePath\lovely.zip" -DestinationPath "$gamePath" -Force
Write-Host "done." -ForegroundColor Green

Remove-Item "$gamePath\lovely.zip"
Write-Output "lovely injector installed."

# Download Steamodded to %AppData%\Balatro\Mods using git
# Clone the Steamodded repository to %AppData%\Balatro\Mods
# if the directory already exists, just run git pull
$modsPath = "$env:APPDATA\Balatro\Mods"

# if the 'Mods' directory doesn't exist, create it
if (-not (Test-Path $modsPath))
{
  New-Item -ItemType Directory -Path $modsPath
}

# Check if the Steamodded repository is already cloned
if (-not (Test-Path "$modsPath\Steamodded"))
{
  Write-Output "Cloning Steamodded repository to $modsPath\Steamodded..."
  git clone https://github.com/Steamodded/smods.git "$modsPath\Steamodded"
} else
{
  Write-Output "Steamodded already cloned, pulling latest changes..."
  git -C "$modsPath\Steamodded" pull
}

# Clone or update the Steamodded examples repository which now contains example mods
if (-not (Test-Path "$modsPath\Steamodded-examples"))
{
  Write-Output "Cloning Steamodded examples repository to $modsPath\Steamodded-examples..."
  git clone https://github.com/Steamodded/examples.git "$modsPath\Steamodded-examples"
} else
{
  Write-Output "Steamodded examples already cloned, pulling latest changes..."
  git -C "$modsPath\Steamodded-examples" pull
}

# copy example mods (AchievementsEnabler.lua and MoreSpeeds.lua) from the separate examples repo to %AppData%\Balatro\Mods
# if the file already exists, overwrite it
$exampleModsPath = "$modsPath\Steamodded-examples\Mods"
Copy-Item "$exampleModsPath\AchievementsEnabler.lua" "$modsPath\AchievementsEnabler.lua" -Force
Copy-Item "$exampleModsPath\MoreSpeeds.lua" "$modsPath\MoreSpeeds.lua" -Force

Write-Output "Steamodded setup complete."

## PART 2 - Install mods ##
$question = "Would you like to install any mods? (y/N)"
$choices = [System.Management.Automation.Host.ChoiceDescription[]]@("&Yes", "&No")
$default = 1 # default to No
$decision = $host.ui.PromptForChoice("Install Mods", $question, $choices, $default)

switch($decision)
{
  0
  { 

    # ask for user input to install some mods, using the $baseMods array
    $baseMods = @("nh6574/JokerDisplay", "DorkDad141/keyboard-shortcuts", "Balatro-Multiplayer/BalatroMultiplayer")
    $script:modsToInstall = [System.Collections.ArrayList]@()

    Write-Output "Would you like to install any of the following mods?"
    for ($i = 0; $i -lt $baseMods.Length; $i++)
    {
      Write-Output "$($i): $($baseMods[$i])"
    }

    $script:selectedIndex = 0

    # takes an index
    function DisplayItem($index)
    {
      $mod = $baseMods[$index]
      if($modsToInstall -contains $mod)
      {
        Write-Host "[x] $mod" -ForegroundColor Green -NoNewline
      } else
      {
        Write-Host "[ ] $mod" -NoNewline
      }
      if($index -eq $script:selectedIndex)
      {
        Write-Host " <-"
      } else
      {
        Write-Host ""
      }
    }
    # Function to display the list with the selected item highlighted
    function DisplayList
    {
      Clear-Host
      Write-Host "Select mods to install/upgrade:"
      Write-Host "Select an item using the up and down arrow keys, then press Space to mark it."
      Write-Host "Press Enter to confirm selection."
      for ($i = 0; $i -lt $baseMods.Count; $i++)
      {
        DisplayItem $i
      }
    }
    Write-Output 1
    # Function to handle keypresses
    function HandleKeyPress
    {
      $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
      switch ($key)
      {
        38
        { # Up arrow
          if ($script:selectedIndex -gt 0)
          {
            $script:selectedIndex--
          }
        }
        40
        { # Down arrow
          if ($script:selectedIndex -lt $baseMods.Count - 1)
          {
            $script:selectedIndex++
          }
        }
        32
        { # Space bar
          $mod = $baseMods[$script:selectedIndex]
          if($script:modsToInstall.Contains($mod))
          {
            # remove item from array
            $script:modsToInstall.Remove($mod)
          } else
          {
            $script:modsToInstall.Add($mod)
          }
        }
        13
        { # Enter key to exit the loop
          Write-Host "Enter pressed..."
          $script:inloop = $false
        }
      }
    }

    # Main loop to keep the user interacting with the list
    $script:inloop = $true
    while ($script:inloop)
    {
      DisplayList
      HandleKeyPress
    }
    # Install the selected mods
    Write-Output "Installing mods..."

    foreach ($mod in $script:modsToInstall)
    {
      # Check if the mod is already installe
      $moddir = $mod.Split('/')[1]
      if (-not (Test-Path "$modsPath\$moddir"))
      {
        Write-Output "Cloning $mod repository to $modsPath\$mod..."
        git clone "https://github.com/$mod.git" "$modsPath\$moddir"
      } else
      {
        Write-Output "$mod already cloned, pulling latest changes..."
        git -C "$modsPath\$moddir" pull
      }
    }
  }
  1
  { Write-Host "Alright. Feel free to install mods later by running the script again."
  }
}


