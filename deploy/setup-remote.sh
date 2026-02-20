#!/bin/bash
set -euo pipefail
echo "=== Atualizando sistema ==="
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "=== Instalando dependencias ==="
sudo apt-get install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release

echo "=== Instalando Docker ==="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sudo sh
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    echo "Docker instalado"
else
    echo "Docker ja instalado"
fi

echo "=== Criando swap 2GB ==="
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "Swap criado"
else
    echo "Swap ja existe"
fi

echo "=== Abrindo portas no iptables ==="
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT || true
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT || true
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT || true
sudo netfilter-persistent save 2>/dev/null || true

echo "=== Criando diretorio da aplicacao ==="
sudo mkdir -p /opt/igreja-manager
sudo chown $USER:$USER /opt/igreja-manager

echo "=== Verificando instalacao ==="
docker --version || echo "Docker nao encontrado"
docker compose version 2>/dev/null || echo "Docker Compose nao encontrado"
free -h

echo "=== Setup concluido! ==="
