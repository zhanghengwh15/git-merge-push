#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 激活虚拟环境
source "$SCRIPT_DIR/venv/bin/activate"

# 调用 Python 脚本
python "$SCRIPT_DIR/jenkins_release.py" "$@" 