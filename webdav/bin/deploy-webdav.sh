#!/usr/bin/env bash
set -euo pipefail
# 部署 WebDAV 服务到当前机器
# 用法: ./deploy-webdav.sh

# 在 ECS 上
cd ~/dotfiles
stow services
stow scripts

# 启用服务
systemctl --user enable rclone-webdav
systemctl --user enable cloudflared
systemctl --user start rclone-webdav
systemctl --user start cloudflared
