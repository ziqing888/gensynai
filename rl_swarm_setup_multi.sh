#!/bin/bash
# rl_swarm_setup_multi.sh
# 支持 macOS 和 Ubuntu/Debian Linux 系统的 RL Swarm 节点自动安装脚本

# --------------------------
# 1. 操作系统检测
# --------------------------
OS_TYPE=$(uname)
if [[ "$OS_TYPE" == "Darwin" ]]; then
    PLATFORM="macOS"
else
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            PLATFORM="linux"
        else
            echo "不支持的 Linux 发行版: $ID，仅支持 Ubuntu 或 Debian。"
            exit 1
        fi
    else
        echo "无法检测操作系统。"
        exit 1
    fi
fi

# --------------------------
# 2. 定义公共函数
# --------------------------
# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # 无颜色

# 日志输出函数
log() {
    local type="$1"
    local msg="$2"
    case $type in
        "INFO") echo -e "${GREEN}[信息] $(date '+%Y-%m-%d %H:%M:%S') - $msg${NC}" ;;
        "WARN") echo -e "${YELLOW}[警告] $(date '+%Y-%m-%d %H:%M:%S') - $msg${NC}" ;;
        "ERROR") echo -e "${RED}[错误] $(date '+%Y-%m-%d %H:%M:%S') - $msg${NC}" ;;
         *) echo -e "${BLUE}[日志] $(date '+%Y-%m-%d %H:%M:%S') - $msg${NC}" ;;
    esac
}

# 暂停函数，等待用户按回车返回主菜单
pause() {
    read -p "按回车键返回主菜单..."
}

# 横幅显示函数
show_banner() {
    clear
    echo -e "${BLUE}"
    echo "=========================================="
    echo "       RL Swarm 节点自动安装脚本         "
    if [[ "$PLATFORM" == "macOS" ]]; then
        echo "           (macOS 版本)                 "
    else
        echo "          (Linux 版本)                  "
    fi
    echo "       当前日期: $(date '+%Y-%m-%d')     "
    echo "=========================================="
    echo -e "${NC}"
    echo "欢迎使用此脚本设置 RL Swarm 节点！"
    echo "本脚本将帮助您安装依赖、配置节点并启动 Web UI。"
    echo ""
}

# 检查命令执行状态
check_status() {
    if [ $? -eq 0 ]; then
        log "INFO" "$1 成功完成！"
    else
        log "ERROR" "$1 失败，请检查日志并重试。"
        exit 1
    fi
}

# --------------------------
# 3. 根据平台定义各功能函数
# --------------------------
# 依赖安装
install_dependencies() {
    if [[ "$PLATFORM" == "linux" ]]; then
        log "INFO" "正在更新系统包..."
        sudo apt-get update && sudo apt-get upgrade -y
        check_status "系统包更新"
        
        log "INFO" "正在安装通用工具..."
        sudo apt-get install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
        check_status "通用工具安装"
        
        # Docker 安装
        if command -v docker &>/dev/null; then
            log "INFO" "Docker 已经安装，跳过 Docker 安装。"
        else
            log "INFO" "正在安装 Docker..."
            for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
                sudo apt-get remove -y $pkg
            done
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo docker run hello-world
            check_status "Docker 安装"
            sudo usermod -aG docker $USER
            log "INFO" "已将当前用户添加到 Docker 组，无需 sudo 运行 Docker。"
        fi
        
        # Python 安装
        if command -v python3 &>/dev/null; then
            log "INFO" "Python 已经安装，跳过 Python 安装。"
        else
            log "INFO" "正在安装 Python..."
            sudo apt-get install -y python3 python3-pip
            check_status "Python 安装"
        fi
    elif [[ "$PLATFORM" == "macOS" ]]; then
        log "INFO" "正在更新 Homebrew..."
        brew update
        check_status "Homebrew 更新"
        
        log "INFO" "正在安装通用工具..."
        brew install curl git wget jq nano automake autoconf tmux htop lz4 ncdu
        check_status "通用工具安装"
        
        # Docker 检查
        if command -v docker &>/dev/null; then
            log "INFO" "Docker 已经安装，跳过 Docker 安装。"
        else
            log "WARN" "未检测到 Docker。请先安装 Docker Desktop: https://www.docker.com/products/docker-desktop"
            exit 1
        fi
        
        # Python 安装
        if command -v python3 &>/dev/null; then
            log "INFO" "Python 已经安装，跳过 Python 安装。"
        else
            log "INFO" "正在安装 Python..."
            brew install python
            check_status "Python 安装"
        fi
    fi
}

# 克隆仓库
clone_repository() {
    REPO_URL="https://github.com/gensyn-ai/rl-swarm/"
    TARGET_DIR="rl-swarm"
    if [ -d "$TARGET_DIR" ]; then
        log "WARN" "目录 $TARGET_DIR 已存在，是否更新仓库？(y/n)"
        read -r update_choice
        if [[ "$update_choice" =~ ^[Yy]$ ]]; then
            cd "$TARGET_DIR" || { log "ERROR" "无法进入 $TARGET_DIR 目录！"; exit 1; }
            git pull
            check_status "仓库更新"
        else
            log "INFO" "跳过克隆，使用现有目录。"
        fi
    else
        log "INFO" "正在克隆 RL Swarm 仓库..."
        git clone "$REPO_URL"
        check_status "仓库克隆"
        cd "$TARGET_DIR" || { log "ERROR" "无法进入 $TARGET_DIR 目录！"; exit 1; }
    fi
    pause
}

# 创建 docker-compose.yaml
create_docker_compose() {
    if [[ "$PLATFORM" == "linux" ]]; then
        # Linux 下自动检测 GPU（启用 runtime: nvidia）
        if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
            log "INFO" "检测到 GPU，启用 nvidia runtime。"
            GPU_RUNTIME="    runtime: nvidia"
        else
            log "INFO" "未检测到 GPU，跳过 GPU runtime 配置。"
            GPU_RUNTIME=""
        fi
    elif [[ "$PLATFORM" == "macOS" ]]; then
        log "INFO" "macOS 平台默认不启用 GPU 支持。"
        GPU_RUNTIME=""
    fi

    # 自动选择 FastAPI 服务的主机端口，默认 8080
    FASTAPI_PORT=8080
    while lsof -i :$FASTAPI_PORT >/dev/null 2>&1; do
        log "WARN" "端口 $FASTAPI_PORT 已被占用，尝试下一个端口..."
        FASTAPI_PORT=$((FASTAPI_PORT+1))
    done
    log "INFO" "fastapi 服务将使用主机端口 $FASTAPI_PORT 映射到容器内的 8000 端口."

    log "INFO" "正在创建 docker-compose.yaml 文件..."
    if [ -f docker-compose.yaml ]; then
        mv docker-compose.yaml docker-compose.yaml.old
        log "INFO" "已备份原有 docker-compose.yaml 文件。"
    fi
    cat <<EOF > docker-compose.yaml
version: '3'

services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.120.0
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "55679:55679"  # Prometheus metrics (optional)
    environment:
      - OTEL_LOG_LEVEL=DEBUG

  swarm_node:
    image: europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.1
    command: ./run_hivemind_docker.sh
$GPU_RUNTIME
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - PEER_MULTI_ADDRS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
      - HOST_MULTI_ADDRS=/ip4/0.0.0.0/tcp/38331
    ports:
      - "38331:38331"
    depends_on:
      - otel-collector

  fastapi:
    build:
      context: .
      dockerfile: Dockerfile.webserver
    environment:
      - OTEL_SERVICE_NAME=rlswarm-fastapi
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - INITIAL_PEERS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
    ports:
      - "${FASTAPI_PORT}:8000"
    depends_on:
      - otel-collector
      - swarm_node
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/healthz"]
      interval: 30s
      retries: 3
EOF
    check_status "docker-compose.yaml 创建"
    pause
}

# 启动服务（后台启动后显示日志，按 Ctrl+C 退出日志查看后再返回主菜单）
start_services() {
    log "INFO" "正在启动 RL Swarm 节点和 Web UI..."
    if docker compose version &>/dev/null; then
      docker compose up --build -d
    else
      docker-compose up --build -d
    fi
    check_status "服务启动"
    log "INFO" "服务已后台运行。"
    log "INFO" "正在显示日志，请按 Ctrl+C 停止日志查看后，再按回车返回主菜单。"
    if docker compose version &>/dev/null; then
      docker compose logs -f
    else
      docker-compose logs -f
    fi
    pause
}

# 查看日志
view_logs() {
    while true; do
        clear
        show_banner
        echo "请选择要查看的日志："
        echo "1) RL Swarm 节点日志"
        echo "2) Web UI 日志"
        echo "3) 遥测收集器日志"
        echo "4) 所有日志"
        echo "5) 返回主菜单"
        read -p "请输入选项 (1-5): " log_choice
        case $log_choice in
            1) docker compose logs -f swarm_node || docker-compose logs -f swarm_node ; break ;;
            2) docker compose logs -f fastapi || docker-compose logs -f fastapi ; break ;;
            3) docker compose logs -f otel-collector || docker-compose logs -f otel-collector ; break ;;
            4) docker compose logs -f || docker-compose logs -f ; break ;;
            5) break ;;
            *) log "WARN" "无效选项，请重试..." ; sleep 2 ;;
        esac
    done
}

# 主菜单
main_menu() {
    while true; do
        clear
        show_banner
        echo "请选择操作："
        echo "1) 安装依赖"
        echo "2) 克隆 RL Swarm 仓库"
        echo "3) 创建 docker-compose.yaml"
        echo "4) 启动 RL Swarm 节点和 Web UI"
        echo "5) 查看日志"
        echo "6) 退出"
        read -p "请输入选项 (1-6): " choice
        case $choice in
            1) install_dependencies ;;
            2) clone_repository ;;
            3) create_docker_compose ;;
            4) start_services ;;
            5) view_logs ;;
            6) log "INFO" "退出脚本，谢谢使用！"; exit 0 ;;
            *) log "WARN" "无效选项，请重试..." ; sleep 2 ;;
        esac
    done
}

# --------------------------
# 4. 脚本入口
# --------------------------
show_banner
log "INFO" "脚本启动中..."
main_menu

