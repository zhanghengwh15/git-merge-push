# Git Merge Push - Windows 版本使用说明

## 概述

这是 `git-merge-push.sh` 脚本的 Windows PowerShell 版本，适用于 Windows 环境下的 Git 操作和 Jenkins 发版流程。

## 文件说明

- `git-merge-push.ps1` - 主要的 PowerShell 脚本（Windows 版本）
- `jenkins_release.ps1` - Jenkins 发版脚本（Windows 版本）
- `jenkins_release.py` - Python 脚本（跨平台，无需修改）

## 环境要求

### 必需软件
1. **PowerShell 5.1+** (Windows 10 默认已安装)
2. **Git** (确保在 PATH 中)
3. **Maven** (如果需要进行编译检查)
4. **Python 3.6+** (如果需要进行 Jenkins 发版)

### Python 依赖
如果需要进行 Jenkins 发版，请安装以下 Python 库：
```powershell
pip install requests
```

## 使用方法

### 基本用法

```powershell
# 仅执行 git 操作（默认提交信息）
.\git-merge-push.ps1

# 指定提交信息
.\git-merge-push.ps1 "修复bug：用户登录问题"

# 指定提交信息和目标分支
.\git-merge-push.ps1 "新功能：用户管理模块" --branch main

# 参数形式
.\git-merge-push.ps1 -m "提交说明" -b main
```

### 高级用法

```powershell
# 执行 git 操作并进行编译检查
.\git-merge-push.ps1 --compile

# 执行 git 操作并触发发版
.\git-merge-push.ps1 --release

# 完整用法：指定提交信息、目标分支、编译检查、发版
.\git-merge-push.ps1 "完整功能发布" --branch main --compile --release
```

### 查看帮助

```powershell
.\git-merge-push.ps1 --help
```

## 功能说明

### 1. Git 操作流程
- 自动查找 Git 仓库根目录
- 自动查找项目根目录（包含 pom.xml）
- 提交当前分支的修改
- 切换到目标分支并合并
- 推送两个分支到远程

### 2. 编译检查（可选）
- 仅在启用 `--compile` 参数时执行
- 在目标分支上进行轻量级 Maven 编译
- 仅进行语法检查和类引用验证
- 遵循 `.gitignore` 文件

### 3. Jenkins 发版（可选）
- 仅在启用 `--release` 参数时执行
- 自动从 pom.xml 获取 artifactId 作为 Job 名称
- 调用 `jenkins_release.ps1` 触发 Jenkins Job

## 配置说明

### Maven Settings 文件路径
默认路径：`C:\Users\{用户名}\.m2\settings.xml`

如需修改，请编辑 `git-merge-push.ps1` 文件中的以下行：
```powershell
$settingsFile = "C:\Users\$env:USERNAME\.m2\settings.xml"
```

### Jenkins 配置
如需修改 Jenkins 配置，请编辑 `jenkins_release.py` 文件中的以下变量：
```python
JENKINS_URL = 'http://192.168.100.43:8080'
JENKINS_USER = 'developer'
JENKINS_PASS = 'developer'
```

## 与原版的主要差异

### 1. 脚本语言
- 原版：Bash Shell
- Windows 版：PowerShell

### 2. 路径处理
- 原版：Unix 风格路径 (`/`)
- Windows 版：Windows 风格路径 (`\`)

### 3. 颜色输出
- 原版：ANSI 转义序列
- Windows 版：PowerShell 颜色参数

### 4. 文件操作
- 原版：Unix 命令 (`cd`, `pwd`, `dirname`)
- Windows 版：PowerShell cmdlet (`Set-Location`, `Get-Location`, `Split-Path`)

### 5. 参数解析
- 原版：Bash 数组和循环
- Windows 版：PowerShell 数组和 switch 语句

## 故障排除

### 1. 执行策略问题
如果遇到执行策略限制，请运行：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. Python 环境问题
确保 Python 在 PATH 中：
```powershell
python --version
```

### 3. Git 命令问题
确保 Git 在 PATH 中：
```powershell
git --version
```

### 4. Maven 命令问题
确保 Maven 在 PATH 中：
```powershell
mvn --version
```

### 5. 权限问题
如果遇到权限问题，请以管理员身份运行 PowerShell。

## 注意事项

1. **路径兼容性**：脚本使用 PowerShell 的 `Join-Path` 函数确保路径兼容性
2. **编码问题**：确保 PowerShell 使用 UTF-8 编码
3. **Git 配置**：确保 Git 已正确配置用户信息
4. **网络连接**：Jenkins 发版需要网络连接到 Jenkins 服务器

## 示例工作流程

```powershell
# 1. 进入项目目录
cd D:\projects\my-java-project

# 2. 执行完整的 git 操作、编译检查和发版
.\git-merge-push.ps1 "发布用户管理功能 v1.2.0" --branch main --compile --release

# 3. 查看执行结果
# 脚本会自动显示每个步骤的执行状态
```

## 技术支持

如果遇到问题，请检查：
1. 所有必需软件是否正确安装
2. 网络连接是否正常
3. 权限是否足够
4. 配置文件是否正确

脚本会在每个步骤显示详细的状态信息，便于问题定位。 