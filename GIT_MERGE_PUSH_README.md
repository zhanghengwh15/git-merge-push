# Git Merge Push + Jenkins 发版集成脚本

## 功能概述

`git-merge-push` 脚本集成了 Git 操作和 Jenkins 发版功能，支持：

1. **Git 操作**：执行分支合并和推送
2. **自动发版**：在所有 Git 操作完成后自动触发 Jenkins 发版
3. **智能识别**：自动从 `pom.xml` 中获取 `artifactId` 作为 Jenkins Job 名称

## 使用方法

### 基本用法

```bash
# 仅执行 Git 操作，不触发发版
./git-merge-push

# 执行 Git 操作并触发发版
./git-merge-push --release
./git-merge-push -r

# 显示帮助信息
./git-merge-push --help
```

### 工作流程

1. **Git 操作阶段**：
   - 执行分支合并
   - 推送代码到远程仓库
   - 其他 Git 相关操作

2. **发版阶段**（仅在使用 `--release` 参数时）：
   - 解析项目根目录下的 `pom.xml` 文件
   - 提取 `artifactId` 作为 Jenkins Job 名称
   - 调用 `jenkins_release.sh` 触发 Jenkins 发版

## 项目要求

### 文件结构

```
项目根目录/
├── pom.xml                    # Maven 配置文件（必须）
├── git-merge-push            # Git 操作脚本
├── jenkins_release.sh        # Jenkins 发版脚本
└── jenkins_release.py        # Python 发版脚本
```

### pom.xml 要求

- 必须包含 `<artifactId>` 标签
- 示例：
```xml
<artifactId>poit-milk-mes</artifactId>
```

## 配置说明

### Jenkins 配置

Jenkins 连接信息在 `jenkins_release.py` 中配置：

```python
JENKINS_URL = 'http://192.168.100.43:8080'
JENKINS_USER = 'developer'
JENKINS_PASS = 'developer'
```

### Git 操作配置

在 `git-merge-push` 脚本的 `execute_git_operations()` 函数中配置你的 Git 操作逻辑。

## 使用示例

### 场景 1：日常开发（仅 Git 操作）

```bash
./git-merge-push
```

输出：
```
[INFO] 开始执行 git-merge-push 流程...
[INFO] 开始执行 git 操作...
[INFO] Git 操作完成
[INFO] 未启用发版模式，流程结束
[SUCCESS] 所有操作完成！
```

### 场景 2：发版流程（Git 操作 + 发版）

```bash
./git-merge-push --release
```

输出：
```
[INFO] 发版模式已启用
[INFO] 开始执行 git-merge-push 流程...
[INFO] 开始执行 git 操作...
[INFO] Git 操作完成
[INFO] Git 操作完成，准备触发发版...
[INFO] 从 pom.xml 获取到 artifactId: poit-milk-mes
[INFO] 准备触发 Jenkins Job: poit-milk-mes
Jenkins Job 'poit-milk-mes' 触发成功！
[SUCCESS] Jenkins Job 'poit-milk-mes' 触发成功！
[SUCCESS] 所有操作完成！
```

## 错误处理

### 常见错误及解决方案

1. **pom.xml 不存在**
   ```
   [ERROR] pom.xml 文件不存在
   ```
   解决：确保在项目根目录下运行脚本

2. **无法获取 artifactId**
   ```
   [ERROR] 无法从 pom.xml 中获取 artifactId
   ```
   解决：检查 pom.xml 中是否包含 `<artifactId>` 标签

3. **Jenkins 脚本不存在**
   ```
   [ERROR] jenkins_release.sh 脚本不存在
   ```
   解决：确保 `jenkins_release.sh` 和 `jenkins_release.py` 在同一目录

4. **Jenkins Job 不存在**
   ```
   触发失败，状态码: 404
   ```
   解决：确保 Jenkins 中存在对应的 Job

## 最佳实践

1. **测试环境验证**：首次使用前在测试环境验证脚本功能
2. **权限检查**：确保 Jenkins 账号有触发 Job 的权限
3. **Job 命名规范**：建议 Jenkins Job 名称与 pom.xml 的 artifactId 保持一致
4. **日志监控**：关注脚本输出的日志信息，及时发现问题

## 扩展功能

如需添加更多功能，可以修改以下部分：

- **Git 操作**：修改 `execute_git_operations()` 函数
- **参数传递**：在 `trigger_jenkins_release()` 函数中添加参数传递
- **错误处理**：增强错误处理和重试机制
- **通知功能**：添加成功/失败通知（邮件、钉钉等） 