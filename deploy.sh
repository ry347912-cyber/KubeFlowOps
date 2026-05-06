#!/bin/bash
# ─────────────────────────────────────────
#  Manual Deploy Script (Emergency Use)
#  Usage: ./scripts/deploy.sh <EC2_HOST>
# ─────────────────────────────────────────
set -e

EC2_HOST="${1:-$EC2_HOST}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_rsa}"

if [ -z "$EC2_HOST" ]; then
  echo "❌ Usage: ./scripts/deploy.sh <EC2_HOST>"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Deploying to: $EC2_HOST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$EC2_HOST" << 'ENDSSH'
  set -e
  cd /home/ubuntu

  echo "📥 Pulling latest image..."
  docker pull "$ECR_REGISTRY/$ECR_REPO:latest"

  echo "♻️ Restarting container..."
  docker stop cicd-app 2>/dev/null || true
  docker rm   cicd-app 2>/dev/null || true

  docker run -d \
    --name cicd-app \
    --restart unless-stopped \
    -p 5000:5000 \
    -e ENVIRONMENT=production \
    "$ECR_REGISTRY/$ECR_REPO:latest"

  sleep 8
  curl -sf http://localhost:5000/health && echo "✅ Healthy!" || echo "❌ Unhealthy!"
ENDSSH

echo "✅ Deploy complete!"
