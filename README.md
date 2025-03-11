# 一键运行 RL Swarm 节点自动化脚本

**RL Swarm** 是由 **GensynAI** 开发的全开源强化学习（RL）训练集群框架，旨在通过互联网构建 RL 节点群。本文档指导你如何使用一键命令安装并运行 RL Swarm 节点及其监控 Web UI 仪表板。

## 硬件要求
- **CPU**：建议至少 16GB 内存（更大模型或数据集推荐更多内存）。
- **GPU（可选）**：支持 CUDA 的 NVIDIA GPU，可提升性能：
  - RTX 3090、RTX 4090、A100、H100 等
- **说明**：若没有 GPU，也可以使用 CPU-only 模式（详见 `docker-compose.yaml` 配置）。

---

## 一键安装和启动步骤

只需在终端中复制以下命令，即可自动完成所有依赖安装、仓库克隆、配置文件生成和容器启动等操作：

```bash
curl -O https://raw.githubusercontent.com/ziqing888/gensynai/refs/heads/main/rl_swarm_setup.sh && \
chmod +x rl_swarm_setup.sh && \
./rl_swarm_setup.sh
```
支持多种系统版本的一键命令
```bash
curl -O https://raw.githubusercontent.com/ziqing888/gensynai/refs/heads/main/rl_swarm_setup_multi.sh && chmod +x rl_swarm_setup_multi.sh && ./rl_swarm_setup_multi.sh
```
![image](https://github.com/user-attachments/assets/ae8f2f77-e877-4f0a-990d-a139a478ddb0)


## 脚本主要功能

### 依赖安装
自动更新系统包，并安装常用工具、Docker、Python 等必要组件。如果已安装则跳过相应步骤。

### 自动检测 GPU 与端口
脚本会自动检测是否存在 NVIDIA GPU（启用 `runtime: nvidia`），并检测默认 FastAPI 映射端口（8080）是否被占用；如被占用，则自动寻找下一个可用端口。

### 仓库克隆与配置
脚本支持自动克隆或更新 RL Swarm 仓库，并生成配置文件 `docker-compose.yaml`。

### 容器启动与日志查看
脚本提供启动容器和实时查看日志的功能，让你能直观监控 RL 节点及 Web UI 的运行状态。

## 运行后注意事项

### 启动后容器日志
容器启动后，部分服务可能在后台运行。你可以在脚本主菜单中选择“查看日志”来实时监控各个服务的运行状态。

### Web UI 访问
- 如果默认端口 8080 被占用，脚本会自动调整为例如 8081。
- 访问地址示例：`http://<你的IP>:8081/`。

### 退出日志查看
在日志界面按 `Ctrl+C` 后，脚本会提示按回车返回主菜单。
