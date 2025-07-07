#!/bin/bash

# 获取脚本所在目录（处理符号链接）
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

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

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] [commit_message] [--branch target_branch]"
    echo ""
    echo "选项:"
    echo "  -r, --release    在所有 git 操作完成后触发 Jenkins 发版"
    echo "  -c, --compile    在目标分支上进行轻量级编译检查"
    echo "  -h, --help       显示此帮助信息"
    echo "  -m, --message    指定提交信息"
    echo "  -b, --branch     指定目标分支（默认: develop）"
    echo ""
    echo "功能:"
    echo "  自动查找 Git 仓库和项目根目录"
    echo "  执行 Git 操作并可选触发 Jenkins 发版"
    echo "  Jenkins Job 名称自动从 pom.xml 的 artifactId 获取"
    echo ""
    echo "示例:"
    echo "  $0                                    # 仅执行 git 操作（默认提交信息）"
    echo "  $0 \"提交说明\"                        # 指定提交信息"
    echo "  $0 \"提交说明\" --branch main          # 指定提交信息和目标分支"
    echo "  $0 -m \"提交说明\" -b main             # 参数形式"
    echo "  $0 --compile                          # 执行 git 操作并进行编译检查"
    echo "  $0 --release                          # 执行 git 操作并触发发版"
    echo "  $0 \"提交说明\" --branch main --compile --release # 完整用法"
    echo ""
    echo "注意: 脚本会自动向上查找 Git 仓库和 pom.xml 文件"
}

# 查找项目根目录（包含 pom.xml 的目录）
find_project_root() {
    local current_dir="$PWD"
    local max_depth=10
    local depth=0
    
    while [ "$depth" -lt "$max_depth" ] && [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/pom.xml" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
        depth=$((depth + 1))
    done
    
    return 1
}

# 查找 Git 仓库根目录
find_git_root() {
    local current_dir="$PWD"
    local max_depth=10
    local depth=0
    
    while [ "$depth" -lt "$max_depth" ] && [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.git" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
        depth=$((depth + 1))
    done
    
    return 1
}

# 检查是否启用发版和编译
ENABLE_RELEASE=false
ENABLE_COMPILE=false
RELEASE_ARGS=()

# 解析发版和编译相关参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --release|-r)
            ENABLE_RELEASE=true
            print_info "发版模式已启用"
            shift
            ;;
        --compile|-c)
            ENABLE_COMPILE=true
            print_info "编译检查模式已启用"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            RELEASE_ARGS+=("$1")
            shift
            ;;
    esac
done

# 从 pom.xml 获取 artifactId
get_artifactId() {
    local pom_file="$1/pom.xml"
    
    if [ ! -f "$pom_file" ]; then
        print_error "pom.xml 文件不存在: $pom_file"
        return 1
    fi
    
    # 使用 awk 提取 artifactId，排除 parent 中的 artifactId
    local artifact_id=$(awk '
    /<parent>/ { in_parent = 1 }
    /<\/parent>/ { in_parent = 0 }
    /<artifactId>/ && !in_parent {
        gsub(/[[:space:]]*<artifactId>/, "")
        gsub(/<\/artifactId>[[:space:]]*/, "")
        print
        exit
    }' "$pom_file")
    
    if [ -z "$artifact_id" ]; then
        print_error "无法从 pom.xml 中获取 artifactId: $pom_file"
        return 1
    fi
    
    echo "$artifact_id"
}

# 执行 git 操作
execute_git_operations() {
    local git_root="$1"
    local project_root="$2"
    shift 2
    local args=("$@")

    print_info "开始执行 git 操作..."
    print_info "Git 仓库根目录: $git_root"
    print_info "项目根目录: $project_root"

    # 切换到 Git 仓库根目录
    cd "$git_root" || {
        print_error "无法切换到 Git 仓库根目录: $git_root"
        return 1
    }

    # 默认值
    local target_branch="develop"
    local commit_message=""

    # 解析参数
    while [[ ${#args[@]} -gt 0 ]]; do
        case "${args[0]}" in
            -b|--branch)
                target_branch="${args[1]}"
                args=("${args[@]:2}")
                ;;
            -m|--message)
                commit_message="${args[1]}"
                args=("${args[@]:2}")
                ;;
            *)
                # 如果没有指定参数名，则认为是 commit 信息
                if [ -z "$commit_message" ]; then
                    commit_message="${args[0]}"
                fi
                args=("${args[@]:1}")
                ;;
        esac
    done

    # 获取当前分支名
    local current_branch
    current_branch=$(git branch --show-current)

    print_info "当前分支: $current_branch"
    print_info "目标分支: $target_branch"

    # 确保有修改被提交
    if [[ -n $(git status -s) ]]; then
        print_info "有未提交的修改，正在提交..."
        git add .

        # 如果没有提供 commit 信息，使用默认的时间信息
        if [ -z "$commit_message" ]; then
            commit_message="$(date '+%Y-%m-%d %H:%M:%S') 提交代码"
            print_info "使用默认 commit 信息: $commit_message"
        fi

        git commit -m "$commit_message"
    else
        print_info "没有未提交的修改"
    fi

    # 切换到目标分支并合并
    print_info "切换到 $target_branch 分支并合并..."
    git checkout "$target_branch"
    local merge_message="$(date '+%Y-%m-%d %H:%M:%S') $current_branch 合并到 $target_branch"
    
    # 执行合并并检查是否出现冲突
    if ! git merge "$current_branch" -m "$merge_message" --no-edit; then
        print_error "合并出现冲突！"
        print_error "请手动解决冲突后，执行以下命令完成合并："
        print_info "1. 解决冲突文件"
        print_info "2. git add ."
        print_info "3. git commit"
        print_info "4. 重新运行此脚本"
        print_warning "当前分支: $target_branch"
        print_warning "原分支: $current_branch"
        print_warning "项目根目录: $project_root"
        exit 1
    fi

    # 如果启用编译检查，在目标分支上进行轻量级编译检查
    if [ "$ENABLE_COMPILE" = true ]; then
        print_info "编译检查模式：在目标分支上进行轻量级编译检查..."
        
        # 检查是否为 Java 项目并进行轻量级编译检查
        if is_java_project "$project_root"; then
            print_info "检测到 Java 项目，在 $target_branch 分支上进行轻量级编译检查..."
            if ! compile_java_project "$project_root"; then
                print_error "Java 项目轻量级编译检查失败！"
                print_error "请解决语法错误或类引用问题后重新运行脚本"
                print_info "当前分支: $target_branch"
                print_info "原分支: $current_branch"
                print_info "项目根目录: $project_root"
                print_warning "编译检查失败，请手动切换回原分支: git checkout $current_branch"
                exit 1
            fi
            print_success "目标分支 $target_branch 轻量级编译检查成功！"
        else
            print_info "非 Java 项目，跳过编译检查步骤"
        fi
    fi

    # 切换回原分支
    print_info "切换回原分支..."
    git checkout "$current_branch"
    
    # 推送两个分支到远程
    print_info "推送分支到远程..."
    git push origin "$current_branch" "$target_branch"

    print_success "Git 操作完成！"
}

# 检查是否为 Java 项目
is_java_project() {
    local project_root="$1"
    [ -f "$project_root/pom.xml" ]
}

# 编译 Java 项目（轻量级语法检查）
compile_java_project() {
    local project_root="$1"
    local settings_file="/Users/zhangheng/jar/settings-yunpingtai.xml"
    
    print_info "开始轻量级编译检查 Java 项目..."
    print_info "项目根目录: $project_root"
    print_info "Maven settings: $settings_file"
    
    # 检查 settings 文件是否存在
    if [ ! -f "$settings_file" ]; then
        print_warning "Maven settings 文件不存在: $settings_file"
        print_info "使用默认 Maven settings"
        settings_file=""
    fi
    
    # 切换到项目根目录
    cd "$project_root" || {
        print_error "无法切换到项目根目录: $project_root"
        return 1
    }
    
    # 检查是否存在 .gitignore 文件
    if [ -f ".gitignore" ]; then
        print_info "检测到 .gitignore 文件，将忽略其中的文件进行编译"
    else
        print_info "未检测到 .gitignore 文件，将编译所有文件"
    fi
    
    # 轻量级编译整个项目（仅语法检查和类引用验证）
    print_info "进行轻量级编译检查（仅语法和类引用验证，遵循 .gitignore）..."
    if [ -n "$settings_file" ]; then
        mvn compile -s "$settings_file" -DskipTests -Dmaven.gitignore.enabled=true
    else
        mvn compile -DskipTests -Dmaven.gitignore.enabled=true
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Java 项目轻量级编译检查成功！"
        print_info "语法检查和类引用验证通过"
    else
        print_error "Java 项目轻量级编译检查失败！"
        print_error "请检查语法错误或缺失的类引用"
        return 1
    fi
}

# 触发 Jenkins 发版
trigger_jenkins_release() {
    local job_name="$1"
    local project_root="$2"
    
    if [ -z "$job_name" ]; then
        print_error "Job 名称不能为空"
        return 1
    fi
    
    print_info "准备触发 Jenkins Job: $job_name"
    
    # 检查 jenkins_release.sh 是否存在
    local jenkins_script="$SCRIPT_DIR/jenkins_release.sh"
    if [ ! -f "$jenkins_script" ]; then
        print_error "jenkins_release.sh 脚本不存在: $jenkins_script"
        return 1
    fi
    
    # 触发 Jenkins Job
    if "$jenkins_script" "$job_name"; then
        print_success "Jenkins Job '$job_name' 触发成功！"
    else
        print_error "Jenkins Job '$job_name' 触发失败！"
        return 1
    fi
}

# 主函数
main() {
    print_info "开始执行 git-merge-push 流程..."
    
    # 查找 Git 仓库根目录
    local git_root
    if ! git_root=$(find_git_root); then
        print_error "未找到 Git 仓库"
        print_error "请确保当前目录或其父目录中存在 .git 目录"
        exit 1
    fi
    
    print_info "找到 Git 仓库根目录: $git_root"
    
    # 查找项目根目录（用于获取 artifactId）
    local project_root
    if ! project_root=$(find_project_root); then
        print_error "未找到包含 pom.xml 的项目根目录"
        print_error "请确保当前目录或其父目录中存在 pom.xml 文件"
        exit 1
    fi
    
    print_info "找到项目根目录: $project_root"
    
    # 执行 git 操作（包含可选的编译检查）
    if ! execute_git_operations "$git_root" "$project_root" "${RELEASE_ARGS[@]}"; then
        print_error "Git 操作失败"
        exit 1
    fi
    
    # 如果启用发版，则触发 Jenkins
    if [ "$ENABLE_RELEASE" = true ]; then
        print_info "Git 操作完成，准备触发发版..."
        
        # 获取 artifactId
        local artifact_id
        if ! artifact_id=$(get_artifactId "$project_root"); then
            print_error "获取 artifactId 失败"
            exit 1
        fi
        
        print_info "从 pom.xml 获取到 artifactId: $artifact_id"
        
        # 触发 Jenkins 发版
        if ! trigger_jenkins_release "$artifact_id" "$project_root"; then
            print_error "发版触发失败"
            exit 1
        fi
    else
        print_info "未启用发版模式，流程结束"
    fi
    
    print_success "所有操作完成！"
}

# 处理命令行参数
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -r|--release)
        # 继续执行主流程
        ;;
    "")
        # 无参数，继续执行主流程
        ;;
    *)
        print_error "未知参数: $1"
        show_help
        exit 1
        ;;
esac

# 执行主函数
main "$@" 