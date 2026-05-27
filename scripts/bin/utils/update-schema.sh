#!/bin/bash
# Update local opencode schema from remote

SCHEMA_URL="https://opencode.ai/config.json"
LOCAL_PATH="/Users/zhuanzmima0000/.config/opencode/schema.json"

# Download to temp file
if ! curl -sL "$SCHEMA_URL" -o /tmp/schema-new.json; then
    echo "[ERROR] Failed to download schema from $SCHEMA_URL" >&2
    exit 1
fi

# Validate JSON
if ! python3 -c "import json; json.load(open('/tmp/schema-new.json'))" 2>/dev/null; then
    echo "[ERROR] Downloaded schema is not valid JSON" >&2
    exit 1
fi

# Check if changed
if [ -f "$LOCAL_PATH" ]; then
    if diff -q "$LOCAL_PATH" /tmp/schema-new.json > /dev/null 2>&1; then
        echo "[OK] Schema is up-to-date ($(date +%Y-%m-%d\ %H:%M:%S))"
        rm /tmp/schema-new.json
        exit 0
    fi
fi

# Update
cp /tmp/schema-new.json "$LOCAL_PATH"
echo "[UPDATED] Schema updated at $(date +%Y-%m-%d\ %H:%M:%S)"
rm -f /tmp/schema-new.json
