#!/usr/bin/env bash
# Upload one image through the full add-item flow and wait for tagging.
# Usage: scripts/add_item.sh path/to/image.png
set -euo pipefail

API="${API:-http://localhost:8000}"
file="$1"

case "$file" in
  *.png | *.PNG)                        ctype="image/png" ;;
  *.jpg | *.jpeg | *.JPG | *.JPEG)      ctype="image/jpeg" ;;
  *) echo "Unsupported file type: $file" >&2; exit 1 ;;
esac

json() { python3 -c "import sys, json; print(json.load(sys.stdin)$1)"; }

resp=$(curl -sf -X POST "$API/items/upload-url" \
  -H "Content-Type: application/json" \
  -d "{\"content_type\": \"$ctype\"}")
item_id=$(echo "$resp" | json "['item']['id']")
url=$(echo "$resp" | json "['upload_url']")

curl -sf -X PUT "$url" -H "Content-Type: $ctype" --data-binary @"$file" > /dev/null
curl -sf -X POST "$API/items/$item_id/process" > /dev/null

status="processing"
for _ in $(seq 1 30); do
  status=$(curl -sf "$API/items/$item_id" | json "['status']")
  if [ "$status" = "ready" ] || [ "$status" = "failed" ]; then
    break
  fi
  sleep 1
done

echo "$item_id  $status  $file"