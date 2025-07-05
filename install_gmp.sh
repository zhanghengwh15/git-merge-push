#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_warning "检测到 root 用户，建议使用普通用户安装"
        read -p "是否继续安装？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "安装已取消"
            exit 0
        fi
    fi
}

# 获取安装目录
get_install_dir() {
    # 优先使用 /usr/local/bin，如果不可写则使用 ~/.local/bin
    if [ -w "/usr/local/bin" ]; then
        echo "/usr/local/bin"
    elif [ -w "$HOME/.local/bin" ]; then
        echo "$HOME/.local/bin"
    else
        print_error "无法找到可写的安装目录"
        print_error "请确保 /usr/local/bin 或 ~/.local/bin 可写"
        exit 1
    fi
}

# 创建符号链接
create_symlink() {
    local install_dir="$1"
    local script_path="$2"
    local link_name="$3"
    
    local link_path="$install_dir/$link_name"
    
    # 如果已存在，先删除
    if [ -L "$link_path" ]; then
        print_info "删除已存在的符号链接: $link_path"
        rm "$link_path"
    elif [ -f "$link_path" ]; then
        print_warning "发现同名文件: $link_path"
        read -p "是否覆盖？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "安装已取消"
            exit 0
        fi
        rm "$link_path"
    fi
    
    # 创建符号链接
    if ln -s "$script_path" "$link_path"; then
        print_success "创建符号链接成功: $link_path -> $script_path"
    else
        print_error "创建符号链接失败"
        return 1
    fi
}

# 检查 PATH 环境变量
check_path() {
    local install_dir="$1"
    
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        print_warning "安装目录 $install_dir 不在 PATH 环境变量中"
        print_info "请将以下行添加到你的 shell 配置文件中（~/.bashrc, ~/.zshrc 等）："
        echo "export PATH=\"$install_dir:\$PATH\""
        echo
        print_info "或者重新登录后使用完整路径: $install_dir/gmp"
    fi
}

# 主安装函数
main() {
    print_info "开始安装 gmp 全局命令..."
    
    # 检查 root 用户
    check_root
    
    # 检查脚本文件是否存在
    local script_path="$SCRIPT_DIR/git-merge-push.sh"
    if [ ! -f "$script_path" ]; then
        print_error "脚本文件不存在: $script_path"
        exit 1
    fi
    
    # 确保脚本有执行权限
    if [ ! -x "$script_path" ]; then
        print_info "为脚本添加执行权限..."
        chmod +x "$script_path"
    fi
    
    # 获取安装目录
    local install_dir
    install_dir=$(get_install_dir)
    print_info "安装目录: $install_dir"
    
    # 创建符号链接
    if ! create_symlink "$install_dir" "$script_path" "gmp"; then
        print_error "安装失败"
        exit 1
    fi
    
    # 检查 PATH
    check_path "$install_dir"
    
    print_success "安装完成！"
    print_info "现在你可以在任何目录下使用以下命令："
    echo "  gmp \"提交说明\" --branch develop    # 基本用法"
    echo "  gmp -m \"提交说明\" -b develop       # 参数形式"
    echo "  gmp --release                       # 带发版功能"
    echo "  gmp --help                          # 显示帮助信息"
    echo ""
    print_info "功能特性："
    echo "  ✅ 自动查找 Git 仓库和项目根目录"
    echo "  ✅ 自动提交未提交的修改"
    echo "  ✅ 自动合并到目标分支并推送"
    echo "  ✅ 支持 Jenkins 发版集成"
    echo "  ✅ 彩色日志输出"
}

# 卸载函数
uninstall() {
    print_info "开始卸载 gmp 全局命令..."
    
    # 获取安装目录
    local install_dir
    install_dir=$(get_install_dir)
    
    local link_path="$install_dir/gmp"
    
    if [ -L "$link_path" ]; then
        if rm "$link_path"; then
            print_success "卸载成功: $link_path"
        else
            print_error "卸载失败"
            exit 1
        fi
    else
        print_warning "未找到安装的符号链接: $link_path"
    fi
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  install     安装 gmp 全局命令（默认）"
    echo "  uninstall   卸载 gmp 全局命令"
    echo "  -h, --help  显示此帮助信息"
    echo ""
    echo "功能:"
    echo "  将 git-merge-push.sh 安装为全局命令 gmp"
    echo "  支持在任何目录下执行 Git 操作和 Jenkins 发版"
    echo "  自动查找项目根目录并执行相应操作"
}

# 处理命令行参数
case "$1" in
    install|"")
        main
        ;;
    uninstall)
        uninstall
        ;;
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        print_error "未知参数: $1"
        show_help
        exit 1
        ;;
esac 