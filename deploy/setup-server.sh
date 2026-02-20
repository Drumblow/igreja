#!/bin/bash
# ============================================================================
# Igreja Manager - Server Setup Script (Oracle Free Tier - Ubuntu/Oracle Linux)
# Run this on the remote server to install Docker and prepare the environment.
# Usage: ssh -i ~/.ssh/igreja.key ubuntu@147.15.109.89 'bash -s' < deploy/setup-server.sh
# ============================================================================

set -euo pipefail

echo "══════════════════════════════════════════════════"
echo "  Igreja Manager — Server Setup"
echo "══════════════════════════════════════════════════"

# Detect OS
if [ -f /etc/oracle-release ] || [ -f /etc/redhat-release ]; then
    OS="rhel"
    echo "→ Detected Oracle Linux / RHEL-based OS"
else
    OS="debian"
    echo "→ Detected Ubuntu / Debian-based OS"
fi

# ── 1. Update System ──────────────────────────────────────────────
echo ""
echo "▶ Updating system packages..."
if [ "$OS" = "rhel" ]; then
    sudo dnf update -y
    sudo dnf install -y git curl wget firewalld
else
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y git curl wget ufw
fi

# ── 2. Install Docker ─────────────────────────────────────────────
if ! command -v docker &> /dev/null; then
    echo ""
    echo "▶ Installing Docker..."
    if [ "$OS" = "rhel" ]; then
        sudo dnf install -y dnf-utils
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        curl -fsSL https://get.docker.com | sudo sh
        sudo apt-get install -y docker-compose-plugin
    fi
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    echo "✓ Docker installed successfully"
else
    echo "✓ Docker already installed: $(docker --version)"
fi

# ── 3. Install Docker Compose (standalone, fallback) ──────────────
if ! docker compose version &> /dev/null; then
    echo ""
    echo "▶ Installing Docker Compose plugin..."
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed: $(docker compose version)"
fi

# ── 4. Configure Firewall ─────────────────────────────────────────
echo ""
echo "▶ Configuring firewall..."
if [ "$OS" = "rhel" ]; then
    sudo systemctl enable firewalld
    sudo systemctl start firewalld
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-port=8080/tcp
    sudo firewall-cmd --reload
else
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8080/tcp
    sudo ufw allow 22/tcp
    echo "y" | sudo ufw enable || true
fi
echo "✓ Firewall configured (ports 80, 443, 8080 open)"

# ── 5. Create app directory ───────────────────────────────────────
echo ""
echo "▶ Creating application directory..."
sudo mkdir -p /opt/igreja-manager
sudo chown $USER:$USER /opt/igreja-manager
echo "✓ App directory ready at /opt/igreja-manager"

# ── 6. Create swap (Oracle Free Tier has limited RAM) ─────────────
if [ ! -f /swapfile ]; then
    echo ""
    echo "▶ Creating 2GB swap file (helps with Rust compilation)..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "✓ Swap file created and enabled"
else
    echo "✓ Swap already configured"
fi

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✓ Server setup complete!"
echo "  Next: Run deploy/deploy.sh to deploy the app."
echo "══════════════════════════════════════════════════"
