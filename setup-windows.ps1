# Windows Environment Setup Script
# For git-merge-push tool

param(
    [switch]$InstallPython,
    [switch]$InstallRequests,
    [switch]$CheckOnly
)

# Color definitions
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$BLUE = "Blue"

# Print colored messages
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $BLUE
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $GREEN
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $YELLOW
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $RED
}

# Show help information
function Show-Help {
    Write-Host "Windows Environment Setup Script"
    Write-Host ""
    Write-Host "Usage: .\setup-windows.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -CheckOnly      Only check environment, do not install"
    Write-Host "  -InstallPython  Install Python (if not installed)"
    Write-Host "  -InstallRequests Install requests library"
    Write-Host "  -h, --help      Show this help information"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\setup-windows.ps1 -CheckOnly"
    Write-Host "  .\setup-windows.ps1 -InstallPython -InstallRequests"
}

# Check PowerShell version
function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion
    Write-Info "PowerShell version: $version"
    
    if ($version.Major -ge 5) {
        Write-Success "PowerShell version meets requirements"
        return $true
    } else {
        Write-Error "PowerShell version too low, need 5.1 or higher"
        return $false
    }
}

# Check Git
function Test-Git {
    try {
        $gitVersion = git --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Git installed: $gitVersion"
            return $true
        } else {
            Write-Error "Git not installed or not in PATH"
            return $false
        }
    }
    catch {
        Write-Error "Git check failed: $_"
        return $false
    }
}

# Check Maven
function Test-Maven {
    try {
        $mvnVersion = mvn --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Maven installed: $($mvnVersion[0])"
            return $true
        } else {
            Write-Warning "Maven not installed or not in PATH (compile check will be unavailable)"
            return $false
        }
    }
    catch {
        Write-Warning "Maven check failed: $_ (compile check will be unavailable)"
        return $false
    }
}

# Check Python
function Test-Python {
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python installed: $pythonVersion"
            return $true
        } else {
            Write-Warning "Python not installed or not in PATH (Jenkins release will be unavailable)"
            return $false
        }
    }
    catch {
        Write-Warning "Python check failed: $_ (Jenkins release will be unavailable)"
        return $false
    }
}

# Check requests library
function Test-RequestsLibrary {
    try {
        python -c "import requests" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "requests library installed"
            return $true
        } else {
            Write-Warning "requests library not installed (Jenkins release will be unavailable)"
            return $false
        }
    }
    catch {
        Write-Warning "requests library check failed: $_ (Jenkins release will be unavailable)"
        return $false
    }
}

# Check execution policy
function Test-ExecutionPolicy {
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    Write-Info "Current execution policy: $policy"
    
    if ($policy -eq "Restricted") {
        Write-Warning "Execution policy too strict, recommend setting to RemoteSigned"
        Write-Info "You can run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
        return $false
    } else {
        Write-Success "Execution policy is correct"
        return $true
    }
}

# Install Python
function Install-Python {
    Write-Info "Installing Python..."
    
    # Check if already installed
    if (Test-Python) {
        Write-Info "Python already installed, skipping installation"
        return $true
    }
    
    # Download Python installer
    $pythonUrl = "https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"
    
    try {
        Write-Info "Downloading Python installer..."
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath
        
        Write-Info "Installing Python..."
        Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1" -Wait
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verify installation
        if (Test-Python) {
            Write-Success "Python installation successful"
            return $true
        } else {
            Write-Error "Python installation failed"
            return $false
        }
    }
    catch {
        Write-Error "Python installation failed: $_"
        return $false
    }
    finally {
        # Clean up installer file
        if (Test-Path $installerPath) {
            Remove-Item $installerPath -Force
        }
    }
}

# Install requests library
function Install-RequestsLibrary {
    Write-Info "Installing requests library..."
    
    # Check if Python is available
    if (-not (Test-Python)) {
        Write-Error "Python not installed, cannot install requests library"
        return $false
    }
    
    # Check if already installed
    if (Test-RequestsLibrary) {
        Write-Info "requests library already installed, skipping installation"
        return $true
    }
    
    try {
        Write-Info "Using pip to install requests library..."
        python -m pip install requests
        
        # Verify installation
        if (Test-RequestsLibrary) {
            Write-Success "requests library installation successful"
            return $true
        } else {
            Write-Error "requests library installation failed"
            return $false
        }
    }
    catch {
        Write-Error "requests library installation failed: $_"
        return $false
    }
}

# Main function
function Main {
    Write-Info "Starting Windows environment check..."
    Write-Host ""
    
    $allChecksPassed = $true
    
    # Check required components
    if (-not (Test-PowerShellVersion)) { $allChecksPassed = $false }
    if (-not (Test-Git)) { $allChecksPassed = $false }
    if (-not (Test-Maven)) { $allChecksPassed = $false }
    if (-not (Test-Python)) { $allChecksPassed = $false }
    if (-not (Test-RequestsLibrary)) { $allChecksPassed = $false }
    if (-not (Test-ExecutionPolicy)) { $allChecksPassed = $false }
    
    Write-Host ""
    
    # If only checking, don't install
    if ($CheckOnly) {
        if ($allChecksPassed) {
            Write-Success "All checks passed! Environment is properly configured."
        } else {
            Write-Warning "Some checks failed, please configure according to the prompts."
        }
        return
    }
    
    # Install components
    if ($InstallPython) {
        if (-not (Test-Python)) {
            if (Install-Python) {
                # Re-check requests library
                if (-not (Test-RequestsLibrary) -and $InstallRequests) {
                    Install-RequestsLibrary
                }
            } else {
                $allChecksPassed = $false
            }
        }
    }
    
    if ($InstallRequests) {
        if (-not (Test-RequestsLibrary)) {
            if (-not (Install-RequestsLibrary)) {
                $allChecksPassed = $false
            }
        }
    }
    
    Write-Host ""
    
    # Final check
    Write-Info "Final environment check..."
    if ($allChecksPassed) {
        Write-Success "Environment setup complete! You can now use the git-merge-push.ps1 script."
        Write-Host ""
        Write-Info "Usage examples:"
        Write-Host "  .\git-merge-push.ps1 --help"
        Write-Host "  .\git-merge-push.ps1 `"commit message`" --compile --release"
    } else {
        Write-Warning "Environment setup not fully complete, please manually install missing components according to the prompts."
    }
}

# Parse command line arguments
if ($args -contains "-h" -or $args -contains "--help") {
    Show-Help
    exit 0
}

# Execute main function
Main 