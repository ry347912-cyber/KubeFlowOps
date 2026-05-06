#!/bin/bash
# ─────────────────────────────────────────────────────
#  Self-Healing Monitor — runs every 2 minutes via cron
#  Monitors app health, auto-restarts on failure,
#  sends Slack alert, and logs everything.
#
#  Cron setup (run once after deploy):
#    */2 * * * * /home/ubuntu/monitor.sh >> /var/log/self_heal.log 2>&1
# ─────────────────────────────────────────────────────

set -euo pipefail

# ── Config ──────────────────────────────────────────
APP_URL="${APP_URL:-http://localhost:5000}"
CONTAINER_NAME="${CONTAINER_NAME:-cicd-app}"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"
LOG_FILE="/var/log/self_heal.log"
METRICS_FILE="/home/ubuntu/metrics.json"
MAX_MEM_PCT=85
MAX_CPU_PCT=90
HEALTH_TIMEOUT=5
MAX_FAILURES=3            # restarts before Slack page
FAILURE_COUNT_FILE="/tmp/heal_failures"

# ── Timestamp ───────────────────────────────────────
ts() { date '+%Y-%m-%d %H:%M:%S'; }

# ── Slack notifier ──────────────────────────────────
notify_slack() {
  local msg="$1"
  if [ -n "$SLACK_WEBHOOK" ]; then
    curl -s -X POST "$SLACK_WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d "{\"text\": \"$msg\"}"
  fi
}

# ── Read / write failure counter ────────────────────
get_failures() { cat "$FAILURE_COUNT_FILE" 2>/dev/null || echo 0; }
set_failures() { echo "$1" > "$FAILURE_COUNT_FILE"; }

# ── Health check ────────────────────────────────────
echo "[$(ts)] 🔍 Health check → $APP_URL/health"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --connect-timeout $HEALTH_TIMEOUT \
  --max-time $HEALTH_TIMEOUT \
  "$APP_URL/health" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
  echo "[$(ts)] ✅ Health check PASSED (HTTP $HTTP_CODE)"
  set_failures 0

  # ── Resource monitoring ───────────────────────────
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then

    MEM_PCT=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.MemPerc}}" \
      | tr -d '%' | cut -d'.' -f1)
    CPU_PCT=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.CPUPerc}}" \
      | tr -d '%' | cut -d'.' -f1)

    echo "[$(ts)] 📊 Resources — CPU: ${CPU_PCT}% | MEM: ${MEM_PCT}%"

    if [ "${MEM_PCT:-0}" -gt "$MAX_MEM_PCT" ]; then
      echo "[$(ts)] ⚠️ HIGH MEMORY (${MEM_PCT}% > ${MAX_MEM_PCT}%) — restarting container"
      notify_slack "⚠️ *Self-Heal* — High memory (${MEM_PCT}%) on \`$CONTAINER_NAME\`. Auto-restarting."
      docker restart "$CONTAINER_NAME"
      echo "[$(ts)] 🔄 Container restarted (memory)"
    fi

    if [ "${CPU_PCT:-0}" -gt "$MAX_CPU_PCT" ]; then
      echo "[$(ts)] ⚠️ HIGH CPU (${CPU_PCT}% > ${MAX_CPU_PCT}%) — alerting"
      notify_slack "⚠️ *Self-Heal* — High CPU (${CPU_PCT}%) on \`$CONTAINER_NAME\`. Investigating."
    fi
  fi

  # ── Append to metrics JSON ────────────────────────
  RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" "$APP_URL/health" || echo "0")
  ENTRY="{\"ts\":\"$(ts)\",\"status\":\"ok\",\"http\":$HTTP_CODE,\"resp_s\":$RESPONSE_TIME}"
  python3 -c "
import json, sys
try:
    data = json.load(open('$METRICS_FILE'))
except: data = {'health_checks': []}
data.setdefault('health_checks', []).append($ENTRY)
data['health_checks'] = data['health_checks'][-500:]  # keep last 500
json.dump(data, open('$METRICS_FILE','w'), indent=2)
" 2>/dev/null || true

else
  # ── FAILURE PATH ──────────────────────────────────
  FAILS=$(get_failures)
  FAILS=$((FAILS + 1))
  set_failures $FAILS

  echo "[$(ts)] ❌ Health check FAILED (HTTP $HTTP_CODE) — failure #$FAILS"

  # Always try restart
  echo "[$(ts)] 🔄 Attempting container restart..."

  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker restart "$CONTAINER_NAME" || true
    sleep 10

    # Verify recovery
    RECHECK=$(curl -s -o /dev/null -w "%{http_code}" \
      --connect-timeout $HEALTH_TIMEOUT "$APP_URL/health" || echo "000")

    if [ "$RECHECK" = "200" ]; then
      echo "[$(ts)] ✅ Recovery successful after restart!"
      notify_slack "✅ *Self-Heal* — \`$CONTAINER_NAME\` recovered after restart. HTTP $RECHECK. MTTR tracked."
      set_failures 0
    else
      echo "[$(ts)] ❌ Recovery FAILED after restart (HTTP $RECHECK)"

      if [ "$FAILS" -ge "$MAX_FAILURES" ]; then
        notify_slack "🚨 *CRITICAL* — \`$CONTAINER_NAME\` DOWN after $FAILS restart attempts! Manual intervention required. URL: $APP_URL"
      fi
    fi
  else
    echo "[$(ts)] ⚠️ Container $CONTAINER_NAME not found — may need full redeploy"
    notify_slack "🚨 *CRITICAL* — Container \`$CONTAINER_NAME\` not found! Redeploy required."
  fi
fi

echo "[$(ts)] ─────────────────────────────────────"
