# Jenkins Release 脚本

## 功能
通过命令行触发 Jenkins 带参数 Job，Jenkins 地址、账号、密码写死在脚本中。

## 快速开始

1. 修改 `jenkins_release.py` 中的 Jenkins 地址、账号、密码。
2. 运行设置脚本：
   ```bash
   ./setup.sh
   ```
3. 使用 shell 脚本调用：
   ```bash
   ./jenkins_release.sh <job_name> param1=val1 param2=val2
   ```
   例如：
   ```bash
   ./jenkins_release.sh my-job version=1.2.3 env=prod
   ```

## 手动安装（可选）

如果你想手动安装依赖：

```bash
# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 运行脚本
python jenkins_release.py <job_name> param1=val1 param2=val2
```

## 项目结构

```
jenkins_shell/
├── jenkins_release.py      # 主 Python 脚本
├── jenkins_release.sh      # Shell 启动脚本（推荐使用）
├── setup.sh               # 一键设置脚本
├── build.sh               # 打包脚本（可选）
├── requirements.txt       # Python 依赖
├── README.md              # 说明文档
└── venv/                  # Python 虚拟环境
```

## 注意事项

- 确保 Jenkins Job 名称正确
- 参数格式：`key=value`
- 如果 Job 不存在，会返回 404 错误
- 脚本会自动处理 Jenkins 认证 