# PowerShell setup script for Windows
# This script provides native PowerShell support alongside the bash setup.sh

param(
    [switch]$Force,
    [switch]$Help
)

# Colors for output
$Color = @{
    Green = "`e[32m"
    Blue = "`e[34m"
    Yellow = "`e[33m"
    Red = "`e[31m"
    Reset = "`e[0m"
}

function Write-Info {
    param([string]$Message)
    Write-Host "$($Color.Blue)[INFO]$($Color.Reset) $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "$($Color.Green)[SUCCESS]$($Color.Reset) $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "$($Color.Yellow)[WARNING]$($Color.Reset) $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "$($Color.Red)[ERROR]$($Color.Reset) $Message"
}

function Show-Help {
    Write-Host "Dotfiles Setup Script for Windows (PowerShell)"
    Write-Host ""
    Write-Host "Usage: .\setup.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help      Show this help message"
    Write-Host "  -Force     Force installation (overwrite existing configs)"
    Write-Host ""
    Write-Host "This script will:"
    Write-Host "  - Install Neovim and Git using winget or chocolatey"
    Write-Host "  - Deploy configurations to appropriate Windows paths"
    Write-Host "  - Add vim=nvim alias to PowerShell profile"
    Write-Host ""
    Write-Host "The script is idempotent - it can be run multiple times safely."
    Write-Host "Use -Force to reinstall configurations even if they exist."
    Write-Host ""
}

function Test-ConfigsIdentical {
    param(
        [string]$LocalDir,
        [string]$RepoDir
    )
    
    if (-not (Test-Path $LocalDir)) { return $false }
    if (-not (Test-Path $RepoDir)) { return $false }
    
    # Simple comparison - in practice you might want more sophisticated comparison
    $localFiles = Get-ChildItem -Recurse $LocalDir | Where-Object { -not $_.PSIsContainer }
    $repoFiles = Get-ChildItem -Recurse $RepoDir | Where-Object { -not $_.PSIsContainer }
    
    if ($localFiles.Count -ne $repoFiles.Count) { return $false }
    
    # Compare file contents (simplified)
    foreach ($localFile in $localFiles) {
        $relativePath = $localFile.FullName.Replace($LocalDir, "")
        $repoFile = Join-Path $RepoDir $relativePath
        
        if (-not (Test-Path $repoFile)) { return $false }
        
        $localContent = Get-Content $localFile.FullName -Raw -ErrorAction SilentlyContinue
        $repoContent = Get-Content $repoFile -Raw -ErrorAction SilentlyContinue
        
        if ($localContent -ne $repoContent) { return $false }
    }
    
    return $true
}

function Install-Packages {
    Write-Info "Checking and installing required packages..."
    
    # Check if winget is available (Windows 10 1709+ / Windows 11)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "Using winget for package installation..."
        
        try {
            winget install --id=Neovim.Neovim --exact --source=winget --accept-package-agreements --accept-source-agreements
            winget install --id=Git.Git --exact --source=winget --accept-package-agreements --accept-source-agreements
            Write-Success "Packages installed successfully via winget"
        }
        catch {
            Write-Error "Failed to install packages via winget: $_"
            exit 1
        }
    }
    # Fall back to chocolatey if winget is not available
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "Using Chocolatey for package installation..."
        
        try {
            choco install neovim git -y
            Write-Success "Packages installed successfully via Chocolatey"
        }
        catch {
            Write-Error "Failed to install packages via Chocolatey: $_"
            exit 1
        }
    }
    else {
        Write-Error "Neither winget nor chocolatey found. Please install one of them first:"
        Write-Error "  - winget: Available on Windows 10 1709+ and Windows 11"
        Write-Error "  - chocolatey: https://chocolatey.org/install"
        exit 1
    }
    
    Write-Success "Package installation completed"
}

function Deploy-Configs {
    Write-Info "Checking configuration deployment..."
    
    $ScriptDir = Split-Path -Parent $PSCommandPath
    $NvimConfigDir = Join-Path $env:LOCALAPPDATA "nvim"
    $TmuxConfigDir = Join-Path $env:USERPROFILE ".config\tmux"
    
    # Create necessary directories
    $LocalAppData = $env:LOCALAPPDATA
    $ConfigDir = Join-Path $env:USERPROFILE ".config"
    
    if (-not (Test-Path $LocalAppData)) { New-Item -ItemType Directory -Path $LocalAppData -Force | Out-Null }
    if (-not (Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
    
    # Deploy nvim config
    $RepoNvimDir = Join-Path $ScriptDir "config\nvim"
    if ($Force -or -not (Test-ConfigsIdentical $NvimConfigDir $RepoNvimDir)) {
        if (Test-Path $NvimConfigDir) {
            Write-Info "Backing up existing nvim config..."
            $BackupDir = "$NvimConfigDir.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item $NvimConfigDir $BackupDir
            Write-Info "Backup created at: $BackupDir"
        }
        
        Write-Info "Installing nvim configuration to $NvimConfigDir..."
        Copy-Item -Recurse $RepoNvimDir $NvimConfigDir
        Write-Success "nvim configuration deployed"
    }
    else {
        Write-Success "nvim configuration is already up to date"
    }
    
    # Deploy tmux config (optional, as tmux may not be available on Windows)
    $RepoTmuxDir = Join-Path $ScriptDir "config\tmux"
    if (Test-Path $RepoTmuxDir) {
        if ($Force -or -not (Test-ConfigsIdentical $TmuxConfigDir $RepoTmuxDir)) {
            if (Test-Path $TmuxConfigDir) {
                Write-Info "Backing up existing tmux config..."
                $BackupDir = "$TmuxConfigDir.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
                Move-Item $TmuxConfigDir $BackupDir
                Write-Info "Backup created at: $BackupDir"
            }
            
            Write-Info "Installing tmux configuration to $TmuxConfigDir..."
            Copy-Item -Recurse $RepoTmuxDir $TmuxConfigDir
            Write-Success "tmux configuration deployed"
        }
        else {
            Write-Success "tmux configuration is already up to date"
        }
    }
    else {
        Write-Info "No tmux configuration found in repository"
    }
}

function Setup-PowerShellAlias {
    Write-Info "Setting up vim->nvim alias in PowerShell..."
    
    $aliasAdded = $false
    
    # PowerShell profile paths
    $profilePaths = @(
        $PROFILE.CurrentUserCurrentHost,
        $PROFILE.CurrentUserAllHosts
    )
    
    foreach ($profilePath in $profilePaths) {
        if ($profilePath) {
            $profileDir = Split-Path -Parent $profilePath
            if (-not (Test-Path $profileDir)) {
                Write-Info "Creating PowerShell profile directory: $profileDir"
                New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            }
            
            $aliasExists = $false
            if (Test-Path $profilePath) {
                $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
                if ($profileContent -match "Set-Alias.*vim.*nvim") {
                    $aliasExists = $true
                }
            }
            
            if (-not $aliasExists) {
                Write-Info "Adding vim=nvim alias to PowerShell profile: $profilePath"
                Add-Content -Path $profilePath -Value "`n# Use nvim as default vim"
                Add-Content -Path $profilePath -Value "Set-Alias -Name vim -Value nvim"
                Write-Success "Added vim=nvim alias to PowerShell profile"
                $aliasAdded = $true
            }
            else {
                Write-Success "vim=nvim alias already exists in PowerShell profile"
            }
        }
    }
    
    if (-not $aliasAdded) {
        Write-Success "All vim=nvim aliases are already configured"
    }
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

if ($Force) {
    Write-Warning "Force mode enabled - existing configurations will be overwritten"
}

try {
    Write-Info "Starting dotfiles setup (PowerShell)..."
    
    Install-Packages
    Deploy-Configs
    Setup-PowerShellAlias
    
    Write-Host ""
    Write-Success "Installation completed successfully!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. Open nvim to complete NvChad setup"
    Write-Host "  2. Restart PowerShell to use 'vim' alias"
    Write-Host "  3. Consider using Windows Terminal or WSL for better terminal experience"
    Write-Host ""
    Write-Info "The setup script can be run multiple times safely."
}
catch {
    Write-Error "Setup failed: $_"
    exit 1
}