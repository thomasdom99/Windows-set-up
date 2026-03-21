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

Write-Host "🍫 Updating Chocolatey..." -ForegroundColor Cyan
choco upgrade chocolatey -y

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
Write-Host "🖥️  Checking packages..." -ForegroundColor Cyan

foreach ($package in $PACKAGES) {
    $installed = choco list --local-only | Select-String "^$package "
    if ($installed) {
        Write-Host "  ✅ $package already installed, skipping." -ForegroundColor Green
    } else {
        Write-Host "  ⬇️  Installing missing app: $package..." -ForegroundColor Yellow
        choco install $package -y --ignore-checksums
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ⚠️  Failed to install $package, skipping..." -ForegroundColor Red
            $FAILED_INSTALLS += $package
        }
    }
}

Write-Host ""
Write-Host "⬆️  Upgrading all packages..." -ForegroundColor Cyan
choco upgrade all -y --ignore-checksums

Write-Host ""
Write-Host "🧹 Cleaning up old versions..." -ForegroundColor Cyan
choco cleanup

Write-Host ""
if ($FAILED_INSTALLS.Count -eq 0) {
    Write-Host "✅ Everything is up to date and nothing is missing!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Done! However the following apps failed to install and may need to be installed manually:" -ForegroundColor Yellow
    foreach ($fail in $FAILED_INSTALLS) {
        Write-Host "   ❌ $fail" -ForegroundColor Red
    }
}
