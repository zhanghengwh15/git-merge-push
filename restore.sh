#!/bin/bash

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

# 恢复原来的 git-merge-push 脚本
restore_original() {
    local backup_file="/usr/local/bin/git-merge-push.backup"
    local target_file="/usr/local/bin/git-merge-push"
    
    if [ ! -f "$backup_file" ]; then
        print_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    # 删除当前的符号链接
    if [ -L "$target_file" ]; then
        print_info "删除当前符号链接: $target_file"
        rm "$target_file"
    fi
    
    # 恢复原来的脚本
    if cp "$backup_file" "$target_file"; then
        print_success "恢复成功: $target_file"
        chmod +x "$target_file"
        print_info "已设置执行权限"
    else
        print_error "恢复失败"
        return 1
    fi
}

# 保留新版本（创建别名）
keep_new_version() {
    local new_script="/usr/local/bin/git-merge-push-new"
    local current_link="/usr/local/bin/git-merge-push"
    
    if [ -L "$current_link" ]; then
        if cp "$(readlink -f "$current_link")" "$new_script"; then
            print_success "新版本已保存为: $new_script"
            chmod +x "$new_script"
        fi
    fi
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  restore    恢复原来的 git-merge-push 脚本（默认）"
    echo "  backup     备份新版本并恢复原版本"
    echo "  -h, --help 显示此帮助信息"
    echo ""
    echo "功能:"
    echo "  恢复被覆盖的原始 git-merge-push 脚本"
    echo "  可选择保留新版本作为 git-merge-push-new"
}

# 主函数
main() {
    print_info "开始恢复原来的 git-merge-push 脚本..."
    
    if ! restore_original; then
        print_error "恢复失败"
        exit 1
    fi
    
    print_success "恢复完成！"
    print_info "原来的 git-merge-push 脚本已恢复"
    print_info "使用方法: git-merge-push [commit_message] [-b target_branch]"
}

# 备份并恢复
backup_and_restore() {
    print_info "备份新版本并恢复原版本..."
    
    if ! keep_new_version; then
        print_warning "无法备份新版本"
    fi
    
    if ! restore_original; then
        print_error "恢复失败"
        exit 1
    fi
    
    print_success "操作完成！"
    print_info "新版本已保存为: git-merge-push-new"
    print_info "原版本已恢复为: git-merge-push"
}

# 处理命令行参数
case "$1" in
    restore|"")
        main
        ;;
    backup)
        backup_and_restore
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