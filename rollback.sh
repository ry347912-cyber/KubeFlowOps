#!/bin/bash
# ─────────────────────────────────────────
#  Rollback Script — revert to previous image
#  Usage: ./scripts/rollback.sh <EC2_HOST> <IMAGE_TAG>
# ─────────────────────────────────────────
set -e

EC2_HOST="${1:-$EC2_HOST}"
IMAGE_TAG="${2:-previous}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_rsa}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏪ Rolling back to tag: $IMAGE_TAG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ssh -i "$SSH_KEY" ubuntu@"$EC2_HOST" << ENDSSH
  docker stop cicd-app 2>/dev/null || true
  docker rm   cicd-app 2>/dev/null || true

  docker run -d \
    --name cicd-app \
    --restart unless-stopped \
    -p 5000:5000 \
    "$ECR_REGISTRY/$ECR_REPO:${IMAGE_TAG}"

  sleep 8
  curl -sf http://localhost:5000/health && echo "✅ Rollback successful!" || echo "❌ Rollback failed!"
ENDSSH
