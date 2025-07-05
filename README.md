# Git Merge Push 工具集

一个集成了 Git 操作、编译检查和 Jenkins 发版的自动化工具集，支持 Java 项目的完整 CI/CD 流程。

## 🚀 主要功能

### 1. **Git 操作自动化**
- 自动查找 Git 仓库和项目根目录
- 智能分支合并和推送
- 支持自定义提交信息和目标分支

### 2. **轻量级编译检查**
- 可选的 Java 项目语法检查
- 类引用验证
- 遵循 `.gitignore` 规则，忽略不必要的文件

### 3. **Jenkins 发版集成**
- 自动从 `pom.xml` 获取 `artifactId` 作为 Jenkins Job 名称
- 支持带参数的 Jenkins Job 触发
- 完整的错误处理和日志输出

## 📦 项目结构

```
jenkins_shell/
├── git-merge-push.sh          # 主脚本：Git操作 + 编译检查 + 发版
├── git-merge-push             # 可执行文件版本
├── jenkins_release.sh         # Jenkins 发版脚本
├── jenkins_release.py         # Python 发版核心逻辑
├── install.sh                 # 一键安装脚本
├── install_gmp.sh            # Git Merge Push 安装脚本
├── setup.sh                  # 环境设置脚本
├── build.sh                  # 构建脚本
├── restore.sh                # 恢复脚本
├── pom.xml                   # Maven 配置
├── requirements.txt          # Python 依赖
├── .gitignore               # Git 忽略文件配置
├── README.md                # 项目说明
└── GIT_MERGE_PUSH_README.md # 详细使用文档
```

## 🛠️ 快速开始

### 1. 安装依赖

```bash
# 一键安装
./install.sh

# 或者手动安装
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. 基本使用

```bash
# 仅执行 Git 操作（默认提交信息）
./git-merge-push.sh

# 指定提交信息
./git-merge-push.sh "修复用户登录bug"

# 指定目标分支
./git-merge-push.sh "新功能开发" --branch main

# 进行编译检查
./git-merge-push.sh --compile

# 触发 Jenkins 发版
./git-merge-push.sh --release

# 完整流程：编译检查 + 发版
./git-merge-push.sh "发布v1.2.0" --branch main --compile --release
```

## 📋 使用示例

### 场景 1：日常开发
```bash
./git-merge-push.sh "日常代码提交"
```
- 自动提交当前修改
- 合并到 develop 分支
- 推送到远程仓库

### 场景 2：代码质量检查
```bash
./git-merge-push.sh "功能开发完成" --compile
```
- 执行 Git 操作
- 在目标分支上进行轻量级编译检查
- 确保代码语法正确

### 场景 3：生产发版
```bash
./git-merge-push.sh "发布v1.2.0" --branch main --compile --release
```
- 合并到 main 分支
- 编译检查确保代码质量
- 自动触发 Jenkins 发版流程

## ⚙️ 配置说明

### Jenkins 配置
在 `jenkins_release.py` 中配置 Jenkins 连接信息：
```python
JENKINS_URL = 'http://your-jenkins-url:8080'
JENKINS_USER = 'your-username'
JENKINS_PASS = 'your-password'
```

### Git 配置
脚本会自动：
- 查找 Git 仓库根目录
- 查找包含 `pom.xml` 的项目根目录
- 从 `pom.xml` 提取 `artifactId`

## 🔧 高级功能

### 编译检查优化
- 使用 `mvn compile -DskipTests` 进行轻量级检查
- 自动遵循 `.gitignore` 规则
- 忽略 `target/`、`build/`、`dist/` 等构建目录

### 错误处理
- 详细的彩色日志输出
- 编译失败时提供清晰的错误信息
- 自动清理临时文件

### 参数支持
- `-r, --release`: 启用发版模式
- `-c, --compile`: 启用编译检查
- `-b, --branch`: 指定目标分支
- `-m, --message`: 指定提交信息
- `-h, --help`: 显示帮助信息

## 📚 详细文档

更多详细信息请参考：
- [GIT_MERGE_PUSH_README.md](GIT_MERGE_PUSH_README.md) - 详细使用文档
- [安装指南](install_gmp.sh) - 安装说明

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个工具！

## 📄 许可证

本项目采用 MIT 许可证。 