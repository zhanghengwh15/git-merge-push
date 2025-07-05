#!/bin/bash

# 检查虚拟环境是否存在
if [ ! -d "venv" ]; then
    echo "虚拟环境不存在，请先运行 ./setup.sh"
    exit 1
fi

# 激活虚拟环境
source venv/bin/activate

# 安装 pyinstaller（如果还没有安装）
pip install pyinstaller

# 打包脚本
pyinstaller --onefile jenkins_release.py

echo "打包完成！可执行文件位于 dist/jenkins_release" 