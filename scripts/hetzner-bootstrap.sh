#!/usr/bin/env bash
# =============================================================================
# EPIRBE / Zé — Hetzner VPS Bootstrap Script
# Target: Ubuntu 24.04, CX32, Falkenstein
# Usage: ssh root@<SERVER_IP> 'bash -s' < hetzner-bootstrap.sh
# =============================================================================
set -euo pipefail

SERVER_USER="theo"
CLAWD_REPO="https://github.com/thrmnn/clawd.git"  # adjust if needed

echo "🚀 Starting Hetzner VPS bootstrap..."

# -----------------------------------------------------------------------------
# 1. System update + essentials
# -----------------------------------------------------------------------------
apt-get update -qq && apt-get upgrade -y -qq
apt-get install -y -qq \
  git curl wget unzip build-essential \
  python3 python3-pip python3-venv \
  nginx certbot python3-certbot-nginx \
  htop tmux jq ufw fail2ban ca-certificates gnupg

# Docker official repo (Ubuntu 24.04)
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# -----------------------------------------------------------------------------
# 2. Create non-root user
# -----------------------------------------------------------------------------
if ! id "$SERVER_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$SERVER_USER"
  usermod -aG sudo,docker "$SERVER_USER"
  echo "$SERVER_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$SERVER_USER
  # Copy SSH authorized_keys from root
  mkdir -p /home/$SERVER_USER/.ssh
  cp /root/.ssh/authorized_keys /home/$SERVER_USER/.ssh/
  chown -R $SERVER_USER:$SERVER_USER /home/$SERVER_USER/.ssh
  chmod 700 /home/$SERVER_USER/.ssh
  chmod 600 /home/$SERVER_USER/.ssh/authorized_keys
fi

echo "✅ User $SERVER_USER created"

# -----------------------------------------------------------------------------
# 3. Harden SSH
# -----------------------------------------------------------------------------
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload sshd

# -----------------------------------------------------------------------------
# 4. Firewall (UFW)
# -----------------------------------------------------------------------------
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 8080/tcp   # EPIRBE backend
ufw allow 8005/tcp   # Icecast stream
ufw allow 8501/tcp   # Streamlit (AI Agency)
ufw --force enable

echo "✅ Firewall configured"

# -----------------------------------------------------------------------------
# 5. Docker + Qdrant
# -----------------------------------------------------------------------------
systemctl enable --now docker

# Start Qdrant as persistent container
docker run -d \
  --name qdrant \
  --restart unless-stopped \
  -p 127.0.0.1:6333:6333 \
  -p 127.0.0.1:6334:6334 \
  -v qdrant_storage:/qdrant/storage \
  qdrant/qdrant:latest

echo "✅ Qdrant running on 6333"

# -----------------------------------------------------------------------------
# 6. Node.js (via NVM) — for OpenClaw
# -----------------------------------------------------------------------------
su - $SERVER_USER -c '
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
  nvm install 20
  nvm use 20
  nvm alias default 20
'

echo "✅ Node.js installed"

# -----------------------------------------------------------------------------
# 7. OpenClaw install
# -----------------------------------------------------------------------------
su - $SERVER_USER -c '
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
  npm install -g openclaw
'

echo "✅ OpenClaw installed"

# -----------------------------------------------------------------------------
# 8. Workspace setup
# -----------------------------------------------------------------------------
su - $SERVER_USER -c "
  mkdir -p ~/clawd ~/sidequests ~/projects
  echo 'export PATH=\"\$HOME/.nvm/versions/node/\$(node --version | tr -d v)/bin:\$PATH\"' >> ~/.bashrc
"

echo "✅ Workspace directories created"

# -----------------------------------------------------------------------------
# 9. OpenClaw as systemd service
# -----------------------------------------------------------------------------
cat > /etc/systemd/system/openclaw.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target docker.service

[Service]
Type=simple
User=theo
WorkingDirectory=/home/theo
ExecStart=/bin/bash -c 'source /home/theo/.nvm/nvm.sh && openclaw gateway start'
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw

echo "✅ OpenClaw systemd service configured (not started — needs config first)"

# -----------------------------------------------------------------------------
# 10. Fail2ban
# -----------------------------------------------------------------------------
systemctl enable --now fail2ban

echo ""
echo "============================================"
echo "✅ Bootstrap complete!"
echo ""
echo "NEXT STEPS (as $SERVER_USER):"
echo "  ssh $SERVER_USER@<SERVER_IP>"
echo "  1. Run: openclaw init  (configure API keys)"
echo "  2. Run: openclaw gateway start"
echo "  3. Copy workspace: rsync -avz ~/clawd/ $SERVER_USER@<IP>:~/clawd/"
echo "  4. Copy credentials: rsync -avz ~/clawd/credentials/ $SERVER_USER@<IP>:~/clawd/credentials/"
echo "  5. systemctl start openclaw"
echo "============================================"
