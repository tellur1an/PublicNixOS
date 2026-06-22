#!/bin/bash
# Usage: pinnacle_tag.sh <tag_num> <label>
# Outputs waybar JSON with active class when tag matches state file

TAG_NUM="$1"
TAG_LABEL="$2"

ACTIVE=$(cat /tmp/pinnacle_active_tag 2>/dev/null | tr -d '[:space:]')

if [ "$ACTIVE" = "$TAG_NUM" ]; then
    echo "{\"text\": \"$TAG_LABEL\", \"class\": \"active\", \"tooltip\": \"Tag $TAG_NUM\"}"
else
    echo "{\"text\": \"$TAG_LABEL\", \"class\": \"inactive\", \"tooltip\": \"Tag $TAG_NUM\"}"
fi
