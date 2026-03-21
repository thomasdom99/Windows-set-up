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

# Check choco is available
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
    "winrar",
    "googledrive",
    "virtualbox"
)

Write-Host "Updating Chocolatey..." -ForegroundColor Cyan
& choco upgrade chocolatey -y | Out-Null

Write-Host ""
Write-Host "Checking packages..." -ForegroundColor Cyan

foreach ($package in $PACKAGES) {
    $installed = & choco list --local-only 2>$null | Select-String "^$package "
    if ($installed) {
        Write-Host "  $package already installed, skipping." -ForegroundColor Green
    } else {
        Write-Host "  Installing missing app: $package..." -ForegroundColor Yellow
        & choco install $package -y --no-progress 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
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
Write-Host "Upgrading all packages..." -ForegroundColor Cyan
& choco upgrade all -y --ignore-checksums

Write-Host ""
Write-Host "Cleaning up old versions..." -ForegroundColor Cyan
& choco cleanup | Out-Null

Write-Host ""
if ($FAILED_INSTALLS.Count -eq 0) {
    Write-Host "Everything is up to date and nothing is missing!" -ForegroundColor Green
} else {
    Write-Host "Done! However the following apps failed and may need to be installed manually:" -ForegroundColor Yellow
    foreach ($fail in $FAILED_INSTALLS) {
        Write-Host "   $fail" -ForegroundColor Red
    }
}
