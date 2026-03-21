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
    choco upgrade chocolatey -y
}

# List of packages to install
$PACKAGES = @(
    "spotify",
    "googlechrome",
    "brave",
    "firefox-dev",
    "discord",
    "microsoft-teams",
    "microsoft-365",
    "vscode",
    "bbedit",
    "googledrive",
    "github-desktop",
    "virtualbox",
    "handbrake",
    "vlc",
    "stats-widget",
    "7zip",
    "docker-desktop",
    "postman",
    "bitwarden",
    "notion",
    "steam",
    "chatgpt",
    "claude",
    "drawio",
    "obs-studio",
    "wireshark",
    "python",
    "git",
    "filezilla",
    "xampp",
    "adobereader"
)

Write-Host ""
Write-Host "🖥️  Installing packages..." -ForegroundColor Cyan

foreach ($package in $PACKAGES) {
    $installed = choco list --local-only | Select-String "^$package "
    if ($installed) {
        Write-Host "  ✅ $package already installed, skipping." -ForegroundColor Green
    } else {
        Write-Host "  ⬇️  Installing $package..." -ForegroundColor Yellow
        choco install $package -y --ignore-checksums
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ⚠️  Failed to install $package, skipping..." -ForegroundColor Red
            $FAILED_INSTALLS += $package
        }
    }
}

Write-Host ""
Write-Host "🧹 Cleaning up..." -ForegroundColor Cyan
choco cleanup

Write-Host ""
if ($FAILED_INSTALLS.Count -eq 0) {
    Write-Host "✅ All done! Your Windows PC is set up and ready to go." -ForegroundColor Green
} else {
    Write-Host "⚠️  Done! However the following apps failed to install and may need to be installed manually:" -ForegroundColor Yellow
    foreach ($fail in $FAILED_INSTALLS) {
        Write-Host "   ❌ $fail" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "⚠️  The following apps need to be installed manually:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  📦 Microsoft Store:" -ForegroundColor Cyan
Write-Host "     - Amphetamine (use PowerToys Keep Awake instead)"
Write-Host "     - Speedtest by Ookla"
Write-Host ""
Write-Host "  🌐 Website:" -ForegroundColor Cyan
Write-Host "     - Cisco Packet Tracer → https://www.netacad.com"
Write-Host "     - Ente Auth → https://ente.io/auth"
Write-Host "     - Firefox Developer Edition → https://www.mozilla.org/firefox/developer"
