# This script is used to mod Balatro.
# It will download the required files from GitHub and install them in the correct location.

$steamBasePath = "C:\Program Files (x86)\Steam"
$gameName = "Balatro"
$gamePath = "$steamBasePath\steamapps\common\$gameName"

$lovelyURL = "https://github.com/ethangreen-dev/lovely-injector/releases/latest/download/lovely-x86_64-pc-windows-msvc.zip"

# Download the lovely injector to game directory and unzip it
Write-Output "Downloading lovely injector to $gamePath..."
Invoke-WebRequest -Uri $lovelyURL -OutFile "$gamePath\lovely.zip"
Write-Output "Unzipping lovely injector..."
Expand-Archive -Path "$gamePath\lovely.zip" -DestinationPath "$gamePath" -Force
Remove-Item "$gamePath\lovely.zip"
Write-Output "lovely injector installed."
# Download Steamodded to %AppData%\Balatro\Mods using git
# Check if git is installed, if not, install it using winget (Windows Package Manager)
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if ($null -eq $gitPath)
{
	winget install -e --id Git.Git
}

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
	git clone https://github.com/Steamopollys/Steamodded.git "$modsPath\Steamodded"
} else
{
	Write-Output "Steamodded already cloned, pulling latest changes..."
	git -C "$modsPath\Steamodded" pull
}

# copy example_mods/Mods/AchievementsEnabler.lua and MoreSpeeds.lua to %AppData%\Balatro\Mods\Steamodded\Mods
# if the file already exists, overwrite it
$exampleModsPath = "$modsPath\Steamodded\example_mods\Mods"
Copy-Item "$exampleModsPath\AchievementsEnabler.lua" "$modsPath\AchievementsEnabler.lua" -Force
Copy-Item "$exampleModsPath\MoreSpeeds.lua" "$modsPath\MoreSpeeds.lua" -Force

Write-Output "Balatro modding setup complete."
# ask for user input to install some mods, using the $baseMods array
$baseMods = @("nh6574/JokerDisplay", "DorkDad141/keyboard-shortcuts")
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
	Writee-Host "Select mods to install/upgrade:"
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
