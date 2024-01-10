#!/bin/bash
set -e

function install() {
  if [ -f "/etc/systemd/system/XrayR.service" ] && [ -f "/etc/XrayR" ]; then
    echo "服务已经安装"
    exit 0
  fi
  # 检测系统
  if [ -f /etc/debian_version ]; then
    apt update
    apt install -y curl wget jq
  else
    echo "请使用Debian安装"
    exit 1
  fi
  if [ ! -d "/etc/XrayR" ]; then
    mkdir "/etc/XrayR"
  fi
  cd "/etc/XrayR"
  core_download=$(curl -s https://api.github.com/repos/z719893361/XrayR/releases/latest | jq -r '.assets[0].browser_download_url|select("linux_amd64")')
  if [ -z "$core_download" ]; then
    echo "没有获取到下载地址"
    exit 1
  fi
  wget "$core_download" -O XrayR
  chmod +x XrayR
  if [ ! -f "/etc/XrayR/config.yaml" ]; then
    echo "download XrayR configuration"
    wget https://raw.githubusercontent.com/z719893361/XrayR-Installer/main/config.yaml -O /etc/XrayR/config.yaml
  fi
  if [ ! -f "/etc/systemd/system/XrayR.service" ]; then
    echo "setting XrayR Service"
    wget https://raw.githubusercontent.com/z719893361/XrayR-Installer/main/XrayR.service -O /etc/systemd/system/XrayR.service
    systemctl daemon-reload
    systemctl enable XrayR
  fi
  ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  echo "Asia/Shanghai" > /etc/timezone
  echo "net.core.rmem_max=8388608" >> /etc/sysctl.conf
  echo "net.core.wmem_max=8388608" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_rmem=4096 87380 8388608" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_wmem=4096 87380 8388608" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_mem=8388608 8388608 8388608" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_window_scaling=1" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_timestamps=1" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf
  echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
  sysctl -p
}

function uninstall() {
  if [ -f "/etc/systemd/system/XrayR.service" ]; then
    systemctl stop XrayR
    systemctl disable XrayR
    systemctl daemon-reload
    rm -rf /etc/systemd/system/XrayR.service
  fi
  if [ -d "/etc/XrayR" ]; then
    if [ -f "/etc/XrayR/XrayR" ]; then
      rm -rf /etc/XrayR/XrayR
    fi
    if [ -f "/etc/XrayR/config.yaml" ]; then
      rm -rf /etc/XrayR/config.yaml
    fi
    if [ -z "$(ls -A /etc/XrayR)" ]; then
      rm -rf /etc/XrayR
    else
      echo "/etc/XrayR目录中有其他文件，请手动删除"
    fi
  fi
}

function update() {
  core_download=$(curl -s https://api.github.com/repos/z719893361/XrayR/releases/latest | jq -r '.assets[0].browser_download_url|select("linux_amd64")')
  if [ -z "$core_download" ]; then
    echo "没有获取到下载地址"
    exit 1
  fi
  if ! systemctl list-unit-files | grep -q "^XrayR.service"; then
    echo "服务未安装"
    exit 1
  fi
  cd /etc/XrayR
  is_active=$(systemctl is-active XrayR | xargs echo)
  if [ "$is_active" == "active" ] || [ "$is_active" == "activating" ]; then
    systemctl stop XrayR
  fi
  wget "$core_download" -O XrayR
  chmod +x XrayR
  if [ "$is_active" == "active" ] || [ "$is_active" == "activating" ]; then
    systemctl start XrayR
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    install)
      install
      ;;
    uninstall)
      uninstall
      ;;
    update)
      update
      ;;
    *)
      echo "Invalid argument: $1"
      exit 1
      ;;
  esac
  shift
done
