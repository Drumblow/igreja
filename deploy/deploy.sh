#!/bin/bash
# ============================================================================
# Igreja Manager - Deployment Script (Backend Only)
# Builds Docker image locally, transfers to Oracle Free Tier VM.
# Frontend will be deployed to Vercel separately.
#
# Usage: bash deploy/deploy.sh
# ============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────
SERVER_IP="147.15.109.89"
SERVER_USER="ubuntu"
SSH_KEY="$HOME/.ssh/igreja.key"
REMOTE_DIR="/opt/igreja-manager"

SSH_CMD="ssh -i $SSH_KEY -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP"
SCP_CMD="scp -i $SSH_KEY -o StrictHostKeyChecking=no"

echo "══════════════════════════════════════════════════"
echo "  Igreja Manager — Deploy Backend to $SERVER_IP"
echo "══════════════════════════════════════════════════"

# ── 1. Verify SSH connectivity ────────────────────────────────────
echo ""
echo "▶ Testing SSH connection..."
$SSH_CMD "echo '✓ SSH connection OK'"

# ── 2. Build backend Docker image locally ─────────────────────────
echo ""
echo "▶ Building backend Docker image locally..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"
docker build --platform linux/amd64 -t igreja-backend:latest backend/
echo "✓ Backend image built"

# ── 3. Save and transfer Docker image ─────────────────────────────
echo ""
echo "▶ Saving Docker image..."
docker save igreja-backend:latest | gzip > /tmp/igreja-backend.tar.gz
IMAGE_SIZE=$(du -h /tmp/igreja-backend.tar.gz | cut -f1)
echo "  Image size: $IMAGE_SIZE"

echo "▶ Transferring image to server..."
$SCP_CMD /tmp/igreja-backend.tar.gz $SERVER_USER@$SERVER_IP:/tmp/
rm /tmp/igreja-backend.tar.gz
echo "✓ Image transferred"

# ── 4. Transfer config files ──────────────────────────────────────
echo ""
echo "▶ Transferring config files..."
tar czf /tmp/igreja-config.tar.gz \
    database/ \
    docker-compose.prod.yml \
    deploy/.env.production

$SCP_CMD /tmp/igreja-config.tar.gz $SERVER_USER@$SERVER_IP:/tmp/
rm /tmp/igreja-config.tar.gz

# ── 5. Deploy on server ───────────────────────────────────────────
echo ""
echo "▶ Deploying on server..."

$SSH_CMD << 'REMOTE_SCRIPT'
set -euo pipefail
REMOTE_DIR="/opt/igreja-manager"

mkdir -p $REMOTE_DIR
cd $REMOTE_DIR

# Extract config
tar xzf /tmp/igreja-config.tar.gz
rm /tmp/igreja-config.tar.gz

# Create .env only if not exists (preserve manual edits)
if [ ! -f .env ]; then
    cp deploy/.env.production .env
    echo "  .env created from template"
else
    echo "  .env preserved (already exists)"
fi

# Load Docker image
echo "  Loading Docker image..."
docker load < /tmp/igreja-backend.tar.gz
rm /tmp/igreja-backend.tar.gz
echo "  ✓ Image loaded"

# Deploy
docker compose -f docker-compose.prod.yml down 2>/dev/null || true
docker compose -f docker-compose.prod.yml up -d

echo "  Waiting for services..."
sleep 15

echo ""
echo "Container status:"
docker compose -f docker-compose.prod.yml ps

echo ""
echo "Backend logs (last 15 lines):"
docker compose -f docker-compose.prod.yml logs --tail=15 backend
REMOTE_SCRIPT

# ── 6. Verify deployment ──────────────────────────────────────────
echo ""
echo "▶ Verifying deployment..."
sleep 5

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "http://$SERVER_IP/api/health" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Health check passed (HTTP $HTTP_CODE)"
else
    echo "⚠ Health check returned HTTP $HTTP_CODE (backend may still be starting)"
fi

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✓ Deployment complete!"
echo ""
echo "  📡 API:       http://$SERVER_IP/api/health"
echo "  📖 Swagger:   http://$SERVER_IP/swagger-ui/"
echo ""
echo "  📋 Commands:"
echo "  ssh -i $SSH_KEY $SERVER_USER@$SERVER_IP"
echo "  cd $REMOTE_DIR && docker compose -f docker-compose.prod.yml logs -f"
echo "══════════════════════════════════════════════════"
