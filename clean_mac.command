#!/bin/bash

# Mac 系统数据清理脚本
# 双击即可运行

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

clear
echo "========================================"
echo "        Mac 系统数据清理工具"
echo "========================================"
echo ""

# 记录真实用户的 Home 目录（sudo 后 ~ 会变为 /root）
REAL_HOME="${REAL_HOME:-$HOME}"

# 检查是否有管理员权限
if [ "$EUID" -ne 0 ]; then
    printf "${YELLOW}需要管理员权限，请输入密码...${NC}\n"
    sudo REAL_HOME="$HOME" "$0" "$@"
    exit $?
fi

# 记录清理前可用空间
before=$(df -h / | awk 'NR==2{print $4}')

printf "${BLUE}[1/5] 检查当前系统快照...${NC}\n"
echo "----------------------------------------"
tmutil listlocalsnapshots /
echo ""

printf "${BLUE}[2/5] 清理 Time Machine 本地快照...${NC}\n"
# 阈值设为极大值，意图是尽可能回收快照空间
tmutil thinlocalsnapshots / 1000000000000 4 2>/dev/null
printf "${GREEN}✓ 快照清理完成${NC}\n"
echo ""

printf "${BLUE}[3/5] 清理系统缓存和日志...${NC}\n"
# 用户缓存
rm -rf "$REAL_HOME/Library/Caches/"* 2>/dev/null
echo "  ✓ 用户缓存已清理"

# 系统缓存（仅清理已知安全的目录）
rm -rf /Library/Caches/com.apple.Safari/* 2>/dev/null
rm -rf /Library/Caches/com.apple.dt.Xcode/* 2>/dev/null
rm -rf /Library/Caches/Homebrew/* 2>/dev/null
echo "  ✓ 系统缓存已清理（仅安全目录）"

# 日志：只清理 7 天前的旧日志
find /private/var/log -name "*.log" -mtime +7 -delete 2>/dev/null
find "$REAL_HOME/Library/Logs" -type f -mtime +7 -delete 2>/dev/null
echo "  ✓ 7 天前的旧日志已清理"

printf "${GREEN}✓ 缓存和日志清理完成${NC}\n"
echo ""

printf "${BLUE}[4/5] 清理开发工具缓存...${NC}\n"
# Homebrew
if command -v brew &>/dev/null; then
    brew cleanup --prune=all 2>/dev/null
    echo "  ✓ Homebrew 缓存已清理"
fi
# npm
if [ -d "$REAL_HOME/.npm/_cacache" ]; then
    rm -rf "$REAL_HOME/.npm/_cacache" 2>/dev/null
    echo "  ✓ npm 缓存已清理"
fi
# pip
if [ -d "$REAL_HOME/Library/Caches/pip" ]; then
    rm -rf "$REAL_HOME/Library/Caches/pip" 2>/dev/null
    echo "  ✓ pip 缓存已清理"
fi
printf "${GREEN}✓ 开发工具缓存清理完成${NC}\n"
echo ""

printf "${BLUE}[5/5] 检查大文件...${NC}\n"
large_files=$(find "$REAL_HOME/Downloads" -type f -mtime +7 -size +200M 2>/dev/null)
large_count=$(echo "$large_files" | grep -c . 2>/dev/null || echo 0)
if [ -n "$large_files" ]; then
    echo "  找到 ${large_count} 个可清理的大文件（>200MB，7天前）："
    echo "  ----------------------------------------"
    echo "$large_files" | while read -r f; do
        size=$(du -h "$f" 2>/dev/null | awk '{print $1}')
        name=$(basename "$f")
        printf "  %-8s %s\n" "$size" "$name"
    done
    echo "  ----------------------------------------"
else
    echo "  未发现可清理的大文件"
fi
printf "  ${YELLOW}提示: 请手动检查 ~/Downloads 文件夹${NC}\n"
echo ""

# 记录清理后可用空间
after=$(df -h / | awk 'NR==2{print $4}')

echo "========================================"
printf "${GREEN}         清理完成！${NC}\n"
echo "========================================"
echo ""
echo "可用空间: ${before} → ${after}"
echo ""
echo "建议操作："
echo "  1. 重启 Mac 以完成清理"
echo "  2. 重启后检查: 系统设置 → 通用 → 存储空间"
echo ""
echo -n "是否立即重启？(y/n): "
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    printf "${YELLOW}正在重启...${NC}\n"
    sleep 1
    shutdown -r now
else
    echo ""
    printf "${GREEN}清理完成，请稍后手动重启 Mac${NC}\n"
    echo ""
    echo "按任意键关闭..."
    read -n 1
fi
