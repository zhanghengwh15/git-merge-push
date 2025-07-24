# Git Merge Push - Windows PowerShell Version
# Automatically find Git repository and project root, execute Git operations and optionally trigger Jenkins release

# Get script directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

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
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [options] [commit_message] [--branch target_branch]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -r, --release    Trigger Jenkins release after all Git operations"
    Write-Host "  -c, --compile    Perform lightweight compilation check on target branch"
    Write-Host "  -h, --help       Show this help information"
    Write-Host "  -m, --message    Specify commit message"
    Write-Host "  -b, --branch     Specify target branch (default: develop)"
    Write-Host ""
    Write-Host "Features:"
    Write-Host "  Automatically find Git repository and project root"
    Write-Host "  Execute Git operations and optionally trigger Jenkins release"
    Write-Host "  Jenkins Job name automatically obtained from pom.xml artifactId"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  $($MyInvocation.MyCommand.Name)                                    # Git operations only (default commit message)"
    Write-Host "  $($MyInvocation.MyCommand.Name) `"commit message`"                  # Specify commit message"
    Write-Host "  $($MyInvocation.MyCommand.Name) `"commit message`" --branch main    # Specify commit message and target branch"
    Write-Host "  $($MyInvocation.MyCommand.Name) -m `"commit message`" -b main       # Parameter form"
    Write-Host "  $($MyInvocation.MyCommand.Name) --compile                          # Git operations with compilation check"
    Write-Host "  $($MyInvocation.MyCommand.Name) --release                          # Git operations with release trigger"
    Write-Host "  $($MyInvocation.MyCommand.Name) `"commit message`" --branch main --compile --release # Complete usage"
    Write-Host ""
    Write-Host "Note: Script will automatically search up for Git repository and pom.xml file"
}

# Find project root directory (containing pom.xml)
function Find-ProjectRoot {
    $currentDir = Get-Location
    $maxDepth = 10
    $depth = 0
    
    while ($depth -lt $maxDepth -and $currentDir.Path -ne $currentDir.Drive.Root) {
        if (Test-Path (Join-Path $currentDir.Path "pom.xml")) {
            return $currentDir.Path
        }
        $currentDir = $currentDir.Parent
        $depth++
    }
    
    return $null
}

# Find Git repository root directory
function Find-GitRoot {
    $currentDir = Get-Location
    $maxDepth = 10
    $depth = 0
    
    while ($depth -lt $maxDepth -and $currentDir.Path -ne $currentDir.Drive.Root) {
        if (Test-Path (Join-Path $currentDir.Path ".git")) {
            return $currentDir.Path
        }
        $currentDir = $currentDir.Parent
        $depth++
    }
    
    return $null
}

# Get artifactId from pom.xml
function Get-ArtifactId {
    param([string]$ProjectRoot)
    
    $pomFile = Join-Path $ProjectRoot "pom.xml"
    
    if (-not (Test-Path $pomFile)) {
        Write-Error "pom.xml file does not exist: $pomFile"
        return $null
    }
    
    # Read pom.xml content
    $content = Get-Content $pomFile -Raw
    
    # Use regex to extract artifactId, excluding parent artifactId
    $lines = $content -split "`n"
    $inParent = $false
    $artifactId = $null
    
    foreach ($line in $lines) {
        if ($line -match "<parent>") {
            $inParent = $true
        }
        elseif ($line -match "</parent>") {
            $inParent = $false
        }
        elseif ($line -match "<artifactId>(.+)</artifactId>" -and -not $inParent) {
            $artifactId = $matches[1].Trim()
            break
        }
    }
    
    if (-not $artifactId) {
        Write-Error "Cannot get artifactId from pom.xml: $pomFile"
        return $null
    }
    
    return $artifactId
}

# Execute Git operations
function Execute-GitOperations {
    param(
        [string]$GitRoot,
        [string]$ProjectRoot,
        [string[]]$Args
    )

    Write-Info "Starting Git operations..."
    Write-Info "Git repository root: $GitRoot"
    Write-Info "Project root: $ProjectRoot"

    # Switch to Git repository root
    try {
        Set-Location $GitRoot -ErrorAction Stop
    }
    catch {
        Write-Error "Cannot switch to Git repository root: $GitRoot"
        return $false
    }

    # Default values
    $targetBranch = "develop"
    $commitMessage = ""

    # Parse arguments
    $i = 0
    while ($i -lt $Args.Count) {
        switch ($Args[$i]) {
            "-b" { 
                if ($i + 1 -lt $Args.Count) {
                    $targetBranch = $Args[$i + 1]
                    $i += 2
                } else {
                    Write-Error "Missing value for -b parameter"
                    return $false
                }
            }
            "--branch" { 
                if ($i + 1 -lt $Args.Count) {
                    $targetBranch = $Args[$i + 1]
                    $i += 2
                } else {
                    Write-Error "Missing value for --branch parameter"
                    return $false
                }
            }
            "-m" { 
                if ($i + 1 -lt $Args.Count) {
                    $commitMessage = $Args[$i + 1]
                    $i += 2
                } else {
                    Write-Error "Missing value for -m parameter"
                    return $false
                }
            }
            "--message" { 
                if ($i + 1 -lt $Args.Count) {
                    $commitMessage = $Args[$i + 1]
                    $i += 2
                } else {
                    Write-Error "Missing value for --message parameter"
                    return $false
                }
            }
            default {
                # If no parameter name specified, consider as commit message
                if (-not $commitMessage) {
                    $commitMessage = $Args[$i]
                }
                $i++
            }
        }
    }

    # Get current branch name
    $currentBranch = git branch --show-current
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Cannot get current branch name"
        return $false
    }

    Write-Info "Current branch: $currentBranch"
    Write-Info "Target branch: $targetBranch"

    # Ensure modifications are committed
    $status = git status --porcelain
    if ($status) {
        Write-Info "There are uncommitted changes, committing..."
        git add .
        
        # If no commit message provided, use default time information
        if (-not $commitMessage) {
            $commitMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') commit code"
            Write-Info "Using default commit message: $commitMessage"
        }

        git commit -m $commitMessage
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Commit failed"
            return $false
        }
    } else {
        Write-Info "No uncommitted changes"
    }

    # Switch to target branch and merge
    Write-Info "Switching to $targetBranch branch and merging..."
    git checkout $targetBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to switch to target branch"
        return $false
    }
    
    $mergeMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $currentBranch merged to $targetBranch"
    git merge $currentBranch -m $mergeMessage --no-edit
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Merge failed"
        return $false
    }

    # If compilation check is enabled, perform lightweight compilation check on target branch
    if ($ENABLE_COMPILE) {
        Write-Info "Compilation check mode: performing lightweight compilation check on target branch..."
        
        # Check if it's a Java project and perform lightweight compilation check
        if (Test-JavaProject $ProjectRoot) {
            Write-Info "Java project detected, performing lightweight compilation check on $targetBranch branch..."
            if (-not (Compile-JavaProject $ProjectRoot)) {
                Write-Error "Java project lightweight compilation check failed!"
                Write-Error "Please resolve syntax errors or missing class references and run the script again"
                Write-Info "Current branch: $targetBranch"
                Write-Info "Original branch: $currentBranch"
                Write-Info "Project root: $ProjectRoot"
                Write-Warning "Compilation check failed, please manually switch back to original branch: git checkout $currentBranch"
                exit 1
            }
            Write-Success "Target branch $targetBranch lightweight compilation check successful!"
        } else {
            Write-Info "Non-Java project, skipping compilation check step"
        }
    }

    # Switch back to original branch
    Write-Info "Switching back to original branch..."
    git checkout $currentBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to switch back to original branch"
        return $false
    }
    
    # Push both branches to remote
    Write-Info "Pushing branches to remote..."
    git push origin $currentBranch $targetBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Push failed"
        return $false
    }

    Write-Success "Git operations completed!"
    return $true
}

# Check if it's a Java project
function Test-JavaProject {
    param([string]$ProjectRoot)
    return Test-Path (Join-Path $ProjectRoot "pom.xml")
}

# Compile Java project (lightweight syntax check)
function Compile-JavaProject {
    param([string]$ProjectRoot)
    
    # Maven settings file path in Windows environment (please modify according to actual situation)
    $settingsFile = "C:\Users\$env:USERNAME\.m2\settings.xml"
    
    Write-Info "Starting lightweight compilation check for Java project..."
    Write-Info "Project root: $ProjectRoot"
    Write-Info "Maven settings: $settingsFile"
    
    # Check if settings file exists
    if (-not (Test-Path $settingsFile)) {
        Write-Warning "Maven settings file does not exist: $settingsFile"
        Write-Info "Using default Maven settings"
        $settingsFile = ""
    }
    
    # Switch to project root directory
    try {
        Set-Location $ProjectRoot -ErrorAction Stop
    }
    catch {
        Write-Error "Cannot switch to project root directory: $ProjectRoot"
        return $false
    }
    
    # Check if .gitignore file exists
    if (Test-Path ".gitignore") {
        Write-Info "Detected .gitignore file, will ignore files in it during compilation"
    } else {
        Write-Info "No .gitignore file detected, will compile all files"
    }
    
    # Lightweight compilation of entire project (syntax check and class reference verification only)
    Write-Info "Performing lightweight compilation check (syntax and class reference verification only, following .gitignore)..."
    if ($settingsFile) {
        mvn compile -s $settingsFile -DskipTests -Dmaven.gitignore.enabled=true
    } else {
        mvn compile -DskipTests -Dmaven.gitignore.enabled=true
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Java project lightweight compilation check successful!"
        Write-Info "Syntax check and class reference verification passed"
        return $true
    } else {
        Write-Error "Java project lightweight compilation check failed!"
        Write-Error "Please check syntax errors or missing class references"
        return $false
    }
}

# Trigger Jenkins release
function Trigger-JenkinsRelease {
    param(
        [string]$JobName,
        [string]$ProjectRoot
    )
    
    if (-not $JobName) {
        Write-Error "Job name cannot be empty"
        return $false
    }
    
    Write-Info "Preparing to trigger Jenkins Job: $JobName"
    
    # Check if jenkins_release.ps1 exists
    $jenkinsScript = Join-Path $SCRIPT_DIR "jenkins_release.ps1"
    if (-not (Test-Path $jenkinsScript)) {
        Write-Error "jenkins_release.ps1 script does not exist: $jenkinsScript"
        return $false
    }
    
    # Trigger Jenkins Job
    & $jenkinsScript $JobName
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Jenkins Job '$JobName' triggered successfully!"
        return $true
    } else {
        Write-Error "Jenkins Job '$JobName' trigger failed!"
        return $false
    }
}

# Main function
function Main {
    param([string[]]$Args)
    
    Write-Info "Starting git-merge-push process..."
    
    # Find Git repository root directory
    $gitRoot = Find-GitRoot
    if (-not $gitRoot) {
        Write-Error "Git repository not found"
        Write-Error "Please ensure .git directory exists in current directory or its parent directories"
        exit 1
    }
    
    Write-Info "Found Git repository root: $gitRoot"
    
    # Find project root directory (for getting artifactId)
    $projectRoot = Find-ProjectRoot
    if (-not $projectRoot) {
        Write-Error "Project root directory containing pom.xml not found"
        Write-Error "Please ensure pom.xml file exists in current directory or its parent directories"
        exit 1
    }
    
    Write-Info "Found project root: $projectRoot"
    
    # Execute Git operations (including optional compilation check)
    if (-not (Execute-GitOperations $gitRoot $projectRoot $Args)) {
        Write-Error "Git operations failed"
        exit 1
    }
    
    # If release is enabled, trigger Jenkins
    if ($ENABLE_RELEASE) {
        Write-Info "Git operations completed, preparing to trigger release..."
        
        # Get artifactId
        $artifactId = Get-ArtifactId $projectRoot
        if (-not $artifactId) {
            Write-Error "Failed to get artifactId"
            exit 1
        }
        
        Write-Info "Got artifactId from pom.xml: $artifactId"
        
        # Trigger Jenkins release
        if (-not (Trigger-JenkinsRelease $artifactId $projectRoot)) {
            Write-Error "Release trigger failed"
            exit 1
        }
    } else {
        Write-Info "Release mode not enabled, process ended"
    }
    
    Write-Success "All operations completed!"
}

# Global variables
$script:ENABLE_RELEASE = $false
$script:ENABLE_COMPILE = $false
$script:RELEASE_ARGS = @()

# Parse command line arguments
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--release" { 
            $script:ENABLE_RELEASE = $true
            Write-Info "Release mode enabled"
            $i++
        }
        "-r" { 
            $script:ENABLE_RELEASE = $true
            Write-Info "Release mode enabled"
            $i++
        }
        "--compile" { 
            $script:ENABLE_COMPILE = $true
            Write-Info "Compilation check mode enabled"
            $i++
        }
        "-c" { 
            $script:ENABLE_COMPILE = $true
            Write-Info "Compilation check mode enabled"
            $i++
        }
        "--help" { 
            Show-Help
            exit 0
        }
        "-h" { 
            Show-Help
            exit 0
        }
        default {
            $script:RELEASE_ARGS += $args[$i]
            $i++
        }
    }
}

# Execute main function
Main $script:RELEASE_ARGS 