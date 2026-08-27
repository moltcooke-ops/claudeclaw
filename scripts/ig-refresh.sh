#!/bin/bash
# Auto-refresh Instagram long-lived access token every 50 days
# Cron: 0 9 */50 * * /Users/stevecooke/claudeclaw/scripts/ig-refresh.sh

ENV_FILE="$HOME/claudeclaw/.env"

# Load current values
APP_ID=$(grep IG_APP_ID "$ENV_FILE" | cut -d= -f2-)
APP_SECRET=$(grep IG_APP_SECRET "$ENV_FILE" | cut -d= -f2-)
CURRENT_TOKEN=$(grep IG_ACCESS_TOKEN "$ENV_FILE" | grep -v APP | cut -d= -f2-)

if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ] || [ -z "$CURRENT_TOKEN" ]; then
  echo "[ig-refresh] ERROR: Missing credentials in .env" >&2
  exit 1
fi

# Exchange for a new long-lived token
RESPONSE=$(curl -s "https://graph.facebook.com/oauth/access_token?grant_type=fb_exchange_token&client_id=$APP_ID&client_secret=$APP_SECRET&fb_exchange_token=$CURRENT_TOKEN")
NEW_TOKEN=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

if [ -z "$NEW_TOKEN" ]; then
  echo "[ig-refresh] ERROR: Token exchange failed. Response: $RESPONSE" >&2
  exit 1
fi

# Update .env in place
sed -i '' "s|^IG_ACCESS_TOKEN=.*|IG_ACCESS_TOKEN=$NEW_TOKEN|" "$ENV_FILE"
echo "[ig-refresh] Token refreshed successfully at $(date)"
