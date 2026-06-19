#!/bin/bash

# 1. 遇到任何错误立即退出脚本，防止错误扩大
set -euo pipefail

# 2. 检查是否以 root/sudo 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "错误: 请使用 sudo 或以 root 用户运行此脚本！"
  exit 1
fi

echo "开始安装最新 Nginx 稳定版..."

# 3. 更新软件包列表并安装必要的支持工具
apt update
apt install -y curl gnupg ca-certificates lsb-release

# 4. 自动检测系统类型 (ubuntu 或 debian) 和版本代号 (codename)
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)

# 确保系统是 ubuntu 或 debian
if [ "$OS" != "ubuntu" ] && [ "$OS" != "debian" ]; then
  echo "错误: 本脚本仅支持 Ubuntu 和 Debian 系统。"
  exit 1
fi

echo "检测到系统为: $OS ($CODENAME)"

# 5. 导入 Nginx 官方签名密钥 (增加 --yes 防止覆盖时卡住交互)
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor --yes -o /usr/share/keyrings/nginx-archive-keyring.gpg

# 6. 动态添加官方稳定版仓库 (使用变量 $OS 和 $CODENAME)
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/$OS $CODENAME nginx" > /etc/apt/sources.list.d/nginx.list

# 7. 设置源优先级
cat <<EOF > /etc/apt/preferences.d/99nginx
Package: *
Pin: origin nginx.org
Pin-Priority: 900
EOF

# 8. 更新源并安装 Nginx
apt update
apt install -y nginx

# 9. 启动并设置开机自启
systemctl start nginx
systemctl enable nginx

echo "----------------------------------------"
echo "Nginx 安装成功！当前版本信息如下："
nginx -v
echo "----------------------------------------"