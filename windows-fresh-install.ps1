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

    # Refresh PATH so choco is available in this session
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
    "postman",
    "bitwarden",
    "notion",
    "steam",
    "chatgpt",
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
    "virtualbox"
)

Write-Host ""
Write-Host "Installing packages..." -ForegroundColor Cyan

foreach ($package in $PACKAGES) {
    $installed = & choco list --local-only 2>$null | Select-String "^$package "
    if ($installed) {
        Write-Host "  $package already installed, skipping." -ForegroundColor Green
    } else {
        Write-Host "  Installing $package..." -ForegroundColor Yellow
        & choco install $package -y --no-progress 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            # Retry with --ignore-checksums
            Write-Host "  Retrying $package with --ignore-checksums..." -ForegroundColor Yellow
            & choco install $package -y --no-progress --ignore-checksums 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Failed to install $package, skipping..." -ForegroundColor Red
            $FAILED_INSTALLS += $package
        } else {
            Write-Host "  $package installed successfully." -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Cleaning up..." -ForegroundColor Cyan
& choco cleanup | Out-Null

Write-Host ""
Write-Host "Installing apps via direct download..." -ForegroundColor Cyan

# Adobe Acrobat Reader — dynamically fetch latest version
$adobePath = "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
if (Test-Path $adobePath) {
    Write-Host "  Adobe Acrobat Reader already installed, skipping." -ForegroundColor Green
} else {
    Write-Host "  Fetching latest Adobe Acrobat Reader version..." -ForegroundColor Yellow
    try {
        $adobePage = Invoke-WebRequest -Uri "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/" -UseBasicParsing -UserAgent "Mozilla/5.0"
        $adobeVersion = ($adobePage.Links.href | Where-Object { $_ -match '^\d{10}/$' } | Sort-Object | Select-Object -Last 1) -replace '/',''
    } catch { $adobeVersion = $null }
    if (-not $adobeVersion) {
        $adobeVersion = "2500121288"
        Write-Host "  Using fallback version: $adobeVersion" -ForegroundColor Yellow
    } else {
        Write-Host "  Latest version: $adobeVersion" -ForegroundColor Yellow
    }
    $adobeUrl = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/$adobeVersion/AcroRdrDC${adobeVersion}_MUI.exe"
    $adobeInstaller = "$env:TEMP\AdobeReader.exe"
    Invoke-WebRequest -Uri $adobeUrl -OutFile $adobeInstaller
    Start-Process -FilePath $adobeInstaller -ArgumentList "/sAll /msi /norestart /quiet ALLUSERS=1 EULA_ACCEPT=YES" -Wait
    Remove-Item $adobeInstaller -Force
    Write-Host "  Adobe Acrobat Reader installed." -ForegroundColor Green
}

# Google Drive — permanent redirect URL, always latest
$googledrivePath = "C:\Program Files\Google\Drive File Stream\googledrivesync.exe"
if (Test-Path $googledrivePath) {
    Write-Host "  Google Drive already installed, skipping." -ForegroundColor Green
} else {
    Write-Host "  Downloading Google Drive..." -ForegroundColor Yellow
    $googledriveUrl = "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe"
    $googledriveInstaller = "$env:TEMP\GoogleDriveSetup.exe"
    Invoke-WebRequest -Uri $googledriveUrl -OutFile $googledriveInstaller
    Start-Process -FilePath $googledriveInstaller -ArgumentList "--silent --desktop_shortcut" -Wait
    Remove-Item $googledriveInstaller -Force
    Write-Host "  Google Drive installed." -ForegroundColor Green
}

Write-Host ""
if ($FAILED_INSTALLS.Count -eq 0) {
    Write-Host "All done! Your Windows PC is set up and ready to go." -ForegroundColor Green
} else {
    Write-Host "Done! However the following apps failed and may need to be installed manually:" -ForegroundColor Yellow
    foreach ($fail in $FAILED_INSTALLS) {
        Write-Host "   $fail" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "The following apps need to be installed manually:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Website:" -ForegroundColor Cyan
Write-Host "     - Cisco Packet Tracer -> https://www.netacad.com"
Write-Host "     - Firefox Developer Edition -> https://www.mozilla.org/firefox/developer"
Write-Host "     - Microsoft 365 -> https://www.microsoft.com/microsoft-365"
Write-Host ""
Write-Host "  Microsoft Store:" -ForegroundColor Cyan
Write-Host "     - WhatsApp"
Write-Host "     - Speedtest by Ookla"
Write-Host "     - Windows PowerToys"
