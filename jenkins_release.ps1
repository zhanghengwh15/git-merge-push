# 获取脚本所在目录
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# 颜色定义
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$BLUE = "Blue"

# 打印带颜色的消息
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $BLUE
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $GREEN
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $RED
}

# 显示帮助信息
function Show-Help {
    Write-Host "用法: $($MyInvocation.MyCommand.Name) <job_name> [param1=val1 param2=val2 ...]"
    Write-Host ""
    Write-Host "参数:"
    Write-Host "  job_name     Jenkins Job 名称"
    Write-Host "  param1=val1  可选参数，格式为 key=value"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  $($MyInvocation.MyCommand.Name) my-job"
    Write-Host "  $($MyInvocation.MyCommand.Name) my-job version=1.0.0 branch=main"
    Write-Host ""
    Write-Host "注意: 需要确保 Python 环境和 requests 库已安装"
}

# 检查Python环境
function Test-PythonEnvironment {
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Python 环境检查通过: $pythonVersion"
            return $true
        } else {
            Write-Error "Python 未安装或不在 PATH 中"
            return $false
        }
    } catch {
        Write-Error "Python 环境检查失败: $_"
        return $false
    }
}

# 检查requests库
function Test-RequestsLibrary {
    try {
        python -c "import requests" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "requests 库检查通过"
            return $true
        } else {
            Write-Error "requests 库未安装，请运行: pip install requests"
            return $false
        }
    } catch {
        Write-Error "requests 库检查失败: $_"
        return $false
    }
}

# 调用Python脚本
function Invoke-JenkinsRelease {
    param([string]$JobName, [hashtable]$Params)
    
    # 检查Python环境
    if (-not (Test-PythonEnvironment)) {
        return $false
    }
    
    # 检查requests库
    if (-not (Test-RequestsLibrary)) {
        return $false
    }
    
    # 构建Python脚本参数
    $pythonArgs = @($JobName)
    foreach ($key in $Params.Keys) {
        $pythonArgs += "$key=$($Params[$key])"
    }
    
    # 调用Python脚本
    Write-Info "调用 Python 脚本: jenkins_release.py $($pythonArgs -join ' ')"
    
    $pythonScript = Join-Path $SCRIPT_DIR "jenkins_release.py"
    if (-not (Test-Path $pythonScript)) {
        Write-Error "jenkins_release.py 脚本不存在: $pythonScript"
        return $false
    }
    
    & python $pythonScript @pythonArgs
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Jenkins Job '$JobName' 触发成功！"
        return $true
    } else {
        Write-Error "Jenkins Job '$JobName' 触发失败！"
        return $false
    }
}

# 解析命令行参数
function Parse-Arguments {
    if ($args.Count -eq 0) {
        Show-Help
        exit 1
    }
    
    # 检查帮助参数
    if ($args[0] -eq "-h" -or $args[0] -eq "--help") {
        Show-Help
        exit 0
    }
    
    $jobName = $args[0]
    $params = @{}
    
    # 解析可选参数
    for ($i = 1; $i -lt $args.Count; $i++) {
        $arg = $args[$i]
        if ($arg -match "(.+)=(.+)") {
            $params[$matches[1]] = $matches[2]
        } else {
            Write-Warning "忽略无效参数: $arg"
        }
    }
    
    return $jobName, $params
}

# 主函数
function Main {
    $jobName, $params = Parse-Arguments
    
    Write-Info "开始触发 Jenkins Job: $jobName"
    if ($params.Count -gt 0) {
        Write-Info "参数: $($params | ConvertTo-Json -Compress)"
    }
    
    if (Invoke-JenkinsRelease $jobName $params) {
        Write-Success "Jenkins 发版流程完成！"
        exit 0
    } else {
        Write-Error "Jenkins 发版流程失败！"
        exit 1
    }
}

# 执行主函数
Main 