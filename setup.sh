#!/bin/bash

# 创建虚拟环境
echo "创建虚拟环境..."
python3 -m venv venv

# 激活虚拟环境
echo "激活虚拟环境..."
source venv/bin/activate

# 安装依赖
echo "安装依赖..."
pip install -r requirements.txt

echo "设置完成！"
echo "使用方法："
echo "1. 激活虚拟环境: source venv/bin/activate"
echo "2. 运行脚本: python jenkins_release.py <job_name> [params...]"
echo "3. 或者直接打包: ./build.sh" 