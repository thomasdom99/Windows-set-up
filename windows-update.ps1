# ===========================================
#   Windows Update Script
#   Run this every now and then to keep
#   all your apps up to date via Chocolatey.
#   Also installs any missing apps.
#
#   HOW TO RUN:
#   1. Open PowerShell as Administrator
#   2. Run: Set-ExecutionPolicy Bypass -Scope Process -Force
#   3. Run: .\windows-update.ps1
# ===========================================

$FAILED_INSTALLS = @()

# Refresh PATH to make sure choco is available
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host ""
Write-Host "Windows Update Script" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found! Please run the fresh-install script first." -ForegroundColor Red
    exit 1
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
    "obs-studio",
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

Write-Host "Updating Chocolatey..." -ForegroundColor Cyan
& choco upgrade chocolatey -y | Out-Null

Write-Host ""
Write-Host "Checking packages..." -ForegroundColor Cyan

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
        "obs-studio"       { "OBS Studio" }
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
        Write-Host "  [Downloading] Installing missing app: $package..." -ForegroundColor Yellow
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
Write-Host "Upgrading all packages..." -ForegroundColor Cyan
& choco upgrade all -y --ignore-checksums

Write-Host ""
Write-Host "Cleaning up old versions..." -ForegroundColor Cyan
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
Write-Host "Checking winget apps..." -ForegroundColor Cyan

# Accept winget source agreements upfront to prevent hanging
winget source update --accept-source-agreements 2>&1 | Out-Null

$WINGET_PACKAGES = @(
    @{ Id = "Postman.Postman";       Name = "Postman" },
    @{ Id = "OpenAI.ChatGPT";        Name = "ChatGPT" },
    @{ Id = "Oracle.VirtualBox";     Name = "VirtualBox" }
)

foreach ($pkg in $WINGET_PACKAGES) {
    $wingetCheck = winget list --id $pkg.Id --accept-source-agreements 2>$null | Select-String $pkg.Id
    if ($wingetCheck) {
        Write-Host "  [OK] $($pkg.Name) already installed, skipping." -ForegroundColor Green
    } else {
        Write-Host "  [Downloading] Installing $($pkg.Name)..." -ForegroundColor Yellow
        winget install --id $pkg.Id -e --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] $($pkg.Name) installed successfully." -ForegroundColor Green
        } else {
            Write-Host "  [Failed] Failed to install $($pkg.Name)." -ForegroundColor Red
            $FAILED_INSTALLS += $pkg.Name
        }
    }
}

Write-Host ""
Write-Host "Checking directly downloaded apps..." -ForegroundColor Cyan

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
    Write-Host "Everything is up to date and nothing is missing!" -ForegroundColor Green
} else {
    Write-Host "Done! However the following apps failed and may need to be installed manually:" -ForegroundColor Yellow
    foreach ($fail in $FAILED_INSTALLS) {
        Write-Host "   [Failed] $fail" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Cleaning up Chocolatey logs..." -ForegroundColor Cyan
Remove-Item "C:\ProgramData\chocolatey\logs\*" -Force -ErrorAction SilentlyContinue
Write-Host "[OK] Logs cleared." -ForegroundColor Green
