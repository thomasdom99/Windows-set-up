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
Write-Host "🖥️  Windows Fresh Install Script" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  Before we begin, please confirm the following:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. You are connected to WiFi"
Write-Host "  2. You are signed into the Microsoft Store"
Write-Host "  3. You are running PowerShell as Administrator"
Write-Host ""
$confirm = Read-Host "Have you completed all of the above? (y/n)"
Write-Host ""

if ($confirm -notmatch '^(y|yes|yep|yeah)$') {
    Write-Host "❌ Please complete the checklist above before running this script." -ForegroundColor Red
    Write-Host ""
    Write-Host "  → Sign into Microsoft Store: Open Store → Sign In" -ForegroundColor Yellow
    Write-Host "  → Run PowerShell as Administrator: Right click → Run as Administrator" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "✅ Great! Starting installation..." -ForegroundColor Green
Write-Host ""

$FAILED_INSTALLS = @()

# Install Chocolatey if not already installed
Write-Host "🍫 Checking for Chocolatey..." -ForegroundColor Cyan
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "✅ Chocolatey already installed. Updating..." -ForegroundColor Green
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
    "adobereader",
    "vlc",
    "handbrake",
    "7zip",
    "microsoft-teams",
    "googledrive",
    "virtualbox"
)

Write-Host ""
Write-Host "🖥️  Installing packages..." -ForegroundColor Cyan

foreach ($package in $PACKAGES) {
    $installed = choco list --local-only | Select-String "^$package "
    if ($installed) {
        Write-Host "  ✅ $package already installed, skipping." -ForegroundColor Green
    } else {
        Write-Host "  ⬇️  Installing $package..." -ForegroundColor Yellow
        choco install $package -y --ignore-checksums 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ⚠️  Failed to install $package, skipping..." -ForegroundColor Red
            $FAILED_INSTALLS += $package
        } else {
            Write-Host "  ✅ $package installed successfully." -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "🧹 Cleaning up..." -ForegroundColor Cyan
choco cleanup | Out-Null

Write-Host ""
if ($FAILED_INSTALLS.Count -eq 0) {
    Write-Host "✅ All done! Your Windows PC is set up and ready to go." -ForegroundColor Green
} else {
    Write-Host "⚠️  Done! However the following apps failed and may need to be installed manually:" -ForegroundColor Yellow
    foreach ($fail in $FAILED_INSTALLS) {
        Write-Host "   ❌ $fail" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "⚠️  The following apps need to be installed manually:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  🌐 Website:" -ForegroundColor Cyan
Write-Host "     - Cisco Packet Tracer → https://www.netacad.com"
Write-Host "     - Firefox Developer Edition → https://www.mozilla.org/firefox/developer"
Write-Host "     - Microsoft 365 → https://www.microsoft.com/microsoft-365"
Write-Host ""
Write-Host "  🛍️  Microsoft Store:" -ForegroundColor Cyan
Write-Host "     - WhatsApp"
Write-Host "     - Speedtest by Ookla"
Write-Host "     - Windows PowerToys"
