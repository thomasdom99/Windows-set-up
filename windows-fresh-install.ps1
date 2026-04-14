# ===========================================
#   Windows Fresh Install Script
#   Run this after a fresh format to install
#   all your essential apps via Chocolatey.
#
#   HOW TO RUN:
#   1. Open PowerShell as Administrator
#   2. Run: Set-ExecutionPolicy Bypass -Scope Process -Force
#   3. Run: .\windows-fresh-install.ps1
# ===========================================

# Pre-flight checklist
Write-Host ""
Write-Host "Windows Fresh Install Script" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Before we begin, please confirm the following:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. You are connected to WiFi"
Write-Host "  2. You are signed into the Microsoft Store"
Write-Host "  3. You are running PowerShell as Administrator"
Write-Host ""
$confirm = Read-Host "Have you completed all of the above? (y/n)"
Write-Host ""

if ($confirm -notmatch '^(y|yes|yep|yeah)$') {
    Write-Host "Please complete the checklist above before running this script." -ForegroundColor Red
    Write-Host ""
    Write-Host "  -> Sign into Microsoft Store: Open Store -> Sign In" -ForegroundColor Yellow
    Write-Host "  -> Run PowerShell as Administrator: Right click -> Run as Administrator" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Great! Starting installation..." -ForegroundColor Green
Write-Host ""

$FAILED_INSTALLS = @()

# Install Chocolatey if not already installed
Write-Host "Checking for Chocolatey..." -ForegroundColor Cyan
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "Chocolatey installed and PATH refreshed." -ForegroundColor Green
} else {
    Write-Host "Chocolatey already installed. Updating..." -ForegroundColor Green
    choco upgrade chocolatey -y | Out-Null
}

$PACKAGES = @(
    "spotify",
    "googlechrome",
    "brave",
    "discord",
    "microsoft-teams",
    "vscode",
    "github-desktop",
    "docker-desktop",
    "bitwarden",
    "notion",
    "steam",
    "drawio",
    "wireshark",
    "python",
    "git",
    "filezilla",
    "xampp",
    "vlc",
    "handbrake",
    "winrar",
    "revo-uninstaller",
    "notepadplusplus",
    "epicgameslauncher"
)

Write-Host ""
Write-Host "Installing packages..." -ForegroundColor Cyan

foreach ($package in $PACKAGES) {
    $chocoInstalled = & choco list --local-only 2>$null | Select-String "^$package "

    $registryPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $displayName = switch ($package) {
        "spotify"          { "Spotify" }
        "googlechrome"     { "Google Chrome" }
        "brave"            { "Brave" }
        "discord"          { "Discord" }
        "microsoft-teams"  { "Microsoft Teams" }
        "vscode"           { "Microsoft Visual Studio Code" }
        "github-desktop"   { "GitHub Desktop" }
        "docker-desktop"   { "Docker Desktop" }
        "bitwarden"        { "Bitwarden" }
        "notion"           { "Notion" }
        "steam"            { "Steam" }
        "drawio"           { "draw.io" }
        "wireshark"        { "Wireshark" }
        "python"           { "Python" }
        "git"              { "Git" }
        "filezilla"        { "FileZilla" }
        "xampp"            { "XAMPP" }
        "vlc"              { "VLC media player" }
        "handbrake"        { "HandBrake" }
        "winrar"           { "WinRAR" }
        "revo-uninstaller" { "Revo Uninstaller" }
        "notepadplusplus"  { "Notepad++" }
        "epicgameslauncher"{ "Epic Games Launcher" }
        default            { $package }
    }
    $registryInstalled = Get-ItemProperty $registryPaths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*$displayName*" }

    if ($chocoInstalled -or $registryInstalled) {
        Write-Host "  [OK] $package already installed, skipping." -ForegroundColor Green
    } else {
        Write-Host "  [Downloading] Installing $package..." -ForegroundColor Yellow
        & choco install $package -y --no-progress 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [Downloading] Retrying $package with --ignore-checksums..." -ForegroundColor Yellow
            & choco install $package -y --no-progress --ignore-checksums 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [Failed] Failed to install $package, skipping..." -ForegroundColor Red
            $FAILED_INSTALLS += $package
        } else {
            Write-Host "  [OK] $package installed successfully." -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Cleaning up..." -ForegroundColor Cyan
& choco cleanup | Out-Null

Write-Host ""
Write-Host "Checking for corrupted Chocolatey packages..." -ForegroundColor Cyan

$chocoLib = "C:\ProgramData\chocolatey\lib"
if (Test-Path $chocoLib) {
    $corruptFound = $false
    Get-ChildItem -Path $chocoLib -Directory | ForEach-Object {
        $pkgName = $_.Name
        $nupkgPath = Join-Path $_.FullName "$pkgName.nupkg"
        if (Test-Path $nupkgPath) {
            # Validate nupkg is a real zip file by checking the ZIP magic bytes (PK header)
            $isCorrupt = $false
            try {
                $bytes = [System.IO.File]::ReadAllBytes($nupkgPath)
                if ($bytes.Length -lt 4 -or $bytes[0] -ne 0x50 -or $bytes[1] -ne 0x4B) {
                    $isCorrupt = $true
                }
            } catch {
                $isCorrupt = $true
            }
            if ($isCorrupt) {
                $corruptFound = $true
                Write-Host "  [Fixing] Corrupt nupkg detected: $pkgName - reinstalling..." -ForegroundColor Yellow
                choco uninstall $pkgName -y --force 2>&1 | Out-Null
                choco install $pkgName -y --no-progress 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  [OK] $pkgName reinstalled successfully." -ForegroundColor Green
                } else {
                    Write-Host "  [Failed] $pkgName reinstall failed - may need manual fix." -ForegroundColor Red
                    $FAILED_INSTALLS += $pkgName
                }
            }
        }
    }
    if (-not $corruptFound) {
        Write-Host "  [OK] All Chocolatey packages look healthy." -ForegroundColor Green
    }
} else {
    Write-Host "  [OK] Chocolatey lib folder not found, skipping corruption check." -ForegroundColor Green
}

Write-Host ""
Write-Host "Installing apps via winget..." -ForegroundColor Cyan

# Accept winget source agreements upfront to prevent hanging
winget source update --accept-source-agreements 2>&1 | Out-Null

$WINGET_PACKAGES = @(
    @{ Id = "Postman.Postman";       Name = "Postman";    Source = "winget" },
    @{ Id = "Oracle.VirtualBox";     Name = "VirtualBox"; Source = "winget" },
    @{ Id = "OBSProject.OBSStudio";  Name = "OBS Studio"; Source = "winget" }
)

foreach ($pkg in $WINGET_PACKAGES) {
    $wingetCheck = winget list --id $pkg.Id --accept-source-agreements 2>$null | Select-String $pkg.Id
    if ($wingetCheck) {
        Write-Host "  [OK] $($pkg.Name) already installed, skipping." -ForegroundColor Green
    } else {
        Write-Host "  [Downloading] Installing $($pkg.Name)..." -ForegroundColor Yellow
        winget install --id $pkg.Id -e --source $pkg.Source --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] $($pkg.Name) installed successfully." -ForegroundColor Green
        } else {
            Write-Host "  [Failed] Failed to install $($pkg.Name)." -ForegroundColor Red
            $FAILED_INSTALLS += $pkg.Name
        }
    }
}

Write-Host ""
Write-Host "Installing apps via direct download..." -ForegroundColor Cyan

# Adobe Acrobat Reader
$adobePath = "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
if (Test-Path $adobePath) {
    Write-Host "  [OK] Adobe Acrobat Reader already installed, skipping." -ForegroundColor Green
} else {
    Write-Host "  [Searching] Fetching latest Adobe Acrobat Reader version..." -ForegroundColor Yellow
    try {
        $adobePage = Invoke-WebRequest -Uri "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/" -UseBasicParsing -UserAgent "Mozilla/5.0"
        $adobeVersion = ($adobePage.Links.href | Where-Object { $_ -match '^\d{10}/$' } | Sort-Object | Select-Object -Last 1) -replace '/',''
    } catch { $adobeVersion = $null }
    if (-not $adobeVersion) {
        $adobeVersion = "2500121288"
        Write-Host "  [Searching] Using fallback version: $adobeVersion" -ForegroundColor Yellow
    } else {
        Write-Host "  [Searching] Latest version: $adobeVersion" -ForegroundColor Yellow
    }
    $adobeUrl = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/$adobeVersion/AcroRdrDC${adobeVersion}_MUI.exe"
    $adobeInstaller = "$env:TEMP\AdobeReader.exe"
    Write-Host "  [Downloading] Downloading Adobe Acrobat Reader..." -ForegroundColor Yellow
    (New-Object System.Net.WebClient).DownloadFile($adobeUrl, $adobeInstaller)
    Write-Host "  [Downloading] Installing Adobe Acrobat Reader..." -ForegroundColor Yellow
    Start-Process -FilePath $adobeInstaller -ArgumentList "/sAll /msi /norestart /quiet ALLUSERS=1 EULA_ACCEPT=YES" -Wait
    Remove-Item $adobeInstaller -Force
    Write-Host "  [OK] Adobe Acrobat Reader installed." -ForegroundColor Green
}

# Google Drive
$googledrivePath = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Google Drive*" }
if ($googledrivePath) {
    Write-Host "  [OK] Google Drive already installed, skipping." -ForegroundColor Green
} else {
    Write-Host "  [Downloading] Downloading Google Drive..." -ForegroundColor Yellow
    $googledriveUrl = "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe"
    $googledriveInstaller = "$env:TEMP\GoogleDriveSetup.exe"
    (New-Object System.Net.WebClient).DownloadFile($googledriveUrl, $googledriveInstaller)
    Write-Host "  [Downloading] Installing Google Drive..." -ForegroundColor Yellow
    Start-Process -FilePath $googledriveInstaller -ArgumentList "--silent --desktop_shortcut" -Wait
    Remove-Item $googledriveInstaller -Force
    Write-Host "  [OK] Google Drive installed." -ForegroundColor Green
}

Write-Host ""
if ($FAILED_INSTALLS.Count -eq 0) {
    Write-Host "All done! Your Windows PC is set up and ready to go." -ForegroundColor Green
} else {
    Write-Host "Done! However the following apps failed and may need to be installed manually:" -ForegroundColor Yellow
    foreach ($fail in $FAILED_INSTALLS) {
        Write-Host "   [Failed] $fail" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "The following apps need to be installed manually:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Website:" -ForegroundColor Cyan
Write-Host "     - Cisco Packet Tracer -> https://www.netacad.com"
Write-Host "     - Firefox Developer Edition -> https://www.mozilla.org/firefox/developer"
Write-Host "     - Microsoft 365 -> https://www.microsoft.com/microsoft-365"
Write-Host "     - Battle.net -> https://www.battle.net/download"
Write-Host ""
Write-Host "  Microsoft Store:" -ForegroundColor Cyan
Write-Host "     - ChatGPT -> https://apps.microsoft.com/detail/9NT1R1C2HH7J"
