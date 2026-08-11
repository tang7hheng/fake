#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  fake 安装脚本
#  用法: sudo bash install.sh
#        curl -fsSL https://xxx/install.sh | sudo bash
# ═══════════════════════════════════════════════════════════════
set -eo pipefail 2>/dev/null || true

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

ok_count=0
fail_count=0

ok() {
    echo -e "  ${GREEN}[✓]${RESET} $1"
    ok_count=$((ok_count+1))
}

fail() {
    echo -e "  ${RED}[✗]${RESET} $1"
    echo -e "       ${DIM}$2${RESET}"
    fail_count=$((fail_count+1))
}

warn() {
    echo -e "  ${YELLOW}[!]${RESET} $1"
    echo -e "       ${DIM}$2${RESET}"
}

# ── 检测发行版 ──────────────────────────────────────────
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo -e "  ${GREEN}[✓]${RESET} 检测到发行版: $PRETTY_NAME"
        ok_count=$((ok_count+1))
    else
        fail "检测发行版失败" "不支持的系统，/etc/os-release 不存在"
        return 1
    fi
}

# ── 检测 Shell ─────────────────────────────────────────
detect_shell() {
    local shell_name="${SHELL##*/}"
    echo -e "  ${GREEN}[✓]${RESET} 检测到 Shell: $shell_name"
    ok_count=$((ok_count+1))
}

# ── 安装 xclip ─────────────────────────────────────────
install_xclip() {
    if command -v xclip &>/dev/null; then
        ok "xclip 已安装"
        return
    fi

    echo -e "  ${DIM}  正在安装 xclip...${RESET}"

    local pkg_manager=""
    if command -v apt-get &>/dev/null; then
        pkg_manager="apt-get install -y"
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf install -y"
    elif command -v yum &>/dev/null; then
        pkg_manager="yum install -y"
    elif command -v pacman &>/dev/null; then
        pkg_manager="pacman -S --noconfirm"
    elif command -v zypper &>/dev/null; then
        pkg_manager="zypper install -y"
    fi

    if [[ -n "$pkg_manager" ]]; then
        if sudo $pkg_manager xclip 2>/dev/null; then
            ok "xclip 安装成功"
        else
            fail "xclip 安装失败" "剪贴板功能不可用，但不影响其他功能"
            echo -e "       ${DIM}可稍后手动安装: sudo apt install xclip${RESET}"
        fi
    else
        warn "未识别包管理器" "跳过 xclip 安装，剪贴板功能不可用"
        fail_count=$((fail_count+1))
    fi
}

# ── 安装 fake ──────────────────────────────────────────
install_fake() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local fake_src="$script_dir/fake"

    # 如果是通过 curl 安装的，fake 可能在临时目录
    if [[ ! -f "$fake_src" ]]; then
        # 尝试从当前目录找
        fake_src="./fake"
    fi
    if [[ ! -f "$fake_src" ]]; then
        fail "找不到 fake 文件" "请确保 fake 和 install.sh 在同一目录"
        return 1
    fi

    if sudo cp "$fake_src" /usr/local/bin/fake 2>/dev/null; then
        sudo chmod +x /usr/local/bin/fake 2>/dev/null
        ok "fake 已安装到 /usr/local/bin/fake"
    else
        fail "复制 fake 到 /usr/local/bin/ 失败" "请检查权限: sudo cp fake /usr/local/bin/fake"
        return 1
    fi
}

# ── 注入 Shell 函数 ────────────────────────────────────
inject_shell_func() {
    local target="$HOME/.bashrc"
    [[ "${SHELL:-}" == *zsh* ]] && target="$HOME/.zshrc"

    if grep -q "_fake_init" "$target" 2>/dev/null; then
        ok "Shell 函数已注入 $target"
        return
    fi

    if cat >> "$target" << 'SHELLFUNC' 2>/dev/null

# fake - 快速预填上次复制的命令
_fake_init() {
    if [[ -f /tmp/_fake_cmd ]]; then
        local cmd=$(cat /tmp/_fake_cmd 2>/dev/null)
        if [[ -n "$cmd" ]]; then
            READLINE_LINE="$cmd"
            READLINE_POINT=${#cmd}
        fi
    fi
}
bind -x '"\C-f":_fake_init' 2>/dev/null || true
SHELLFUNC
    then
        ok "Shell 函数已注入 $target"
    else
        fail "注入 Shell 函数失败" "fake 仍可使用，但 Ctrl+F 预填功能不可用"
        echo -e "       ${DIM}可稍后手动执行: fake --inject${RESET}"
    fi
}

# ── 生成系统缓存 ───────────────────────────────────────
generate_cache() {
    # 让 fake 自己检测并生成缓存
    if /usr/local/bin/fake --detect &>/dev/null; then
        ok "系统配置已缓存"
    else
        warn "系统缓存生成跳过" "首次运行 fake 时会自动生成"
    fi
}

# ── 输出汇总 ──────────────────────────────────────────
print_summary() {
    local total=$((ok_count + fail_count))
    echo ""
    echo -e "  ${BOLD}══════════════════════════════════════${RESET}"
    echo -e "  ${BOLD}  安装结果汇总${RESET}"
    echo -e "  ${BOLD}══════════════════════════════════════${RESET}"

    if (( fail_count == 0 )); then
        echo -e "  ${GREEN}状态: 全部成功 ($ok_count/$total)${RESET}"
    else
        echo -e "  ${YELLOW}状态: 基本可用 ($ok_count/$total)${RESET}"
    fi

    echo ""
    echo -e "  ${DIM}下一步: source ~/.bashrc 或重新打开终端${RESET}"
    echo -e "  ${DIM}然后输入 fake 开始使用${RESET}"
    echo -e "  ${BOLD}══════════════════════════════════════${RESET}"
    echo ""
}

# ── 主流程 ─────────────────────────────────────────────
main() {
    # 检查是否以 root/sudo 运行
    if [[ $EUID -ne 0 ]]; then
        echo -e "  ${YELLOW}⚠ 需要管理员权限，请使用 sudo 运行${RESET}"
        echo -e "  ${DIM}sudo bash install.sh${RESET}"
        exit 1
    fi

    echo ""
    echo -e "  ${BOLD}══════════════════════════════════════${RESET}"
    echo -e "  ${BOLD}  fake 安装程序 v1.0.0${RESET}"
    echo -e "  ${BOLD}══════════════════════════════════════${RESET}"
    echo ""

    detect_distro || true
    detect_shell
    install_xclip
    install_fake || true
    inject_shell_func
    generate_cache
    print_summary
}

main
