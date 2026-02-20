#!/bin/bash
# ==============================================
# Deploy Frontend (Flutter Web) to Vercel
# ==============================================
# Usage: ./deploy-frontend.sh [--preview]
#
# By default deploys to production.
# Use --preview for a preview deployment.
# ==============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$(cd "$SCRIPT_DIR/../frontend" && pwd)"
API_URL="${API_URL:-/api}"

echo "=== Igreja Manager — Frontend Deploy ==="
echo "API URL: $API_URL"

# 1. Build Flutter web
echo ""
echo ">>> Building Flutter web..."
cd "$FRONTEND_DIR"
flutter build web --release --dart-define="API_URL=$API_URL"

# 2. Copy vercel.json into build output
echo ""
echo ">>> Preparing Vercel config..."
cp "$FRONTEND_DIR/vercel.json" "$FRONTEND_DIR/build/web/vercel.json"

# 3. Deploy to Vercel
cd "$FRONTEND_DIR/build/web"

PROD_FLAG="--prod"
if [ "$1" = "--preview" ]; then
    PROD_FLAG=""
    echo ">>> Deploying PREVIEW to Vercel..."
else
    echo ">>> Deploying PRODUCTION to Vercel..."
fi

vercel --yes $PROD_FLAG

echo ""
echo "=== Deploy complete! ==="
