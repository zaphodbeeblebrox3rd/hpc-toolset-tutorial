#!/bin/bash

# Update Theme Cache Busting Script
# This script adds timestamps to theme files to force browser cache refresh

THEME_DIR="themes/chicago-booth"
TIMESTAMP=$(date +%s)

echo "Updating theme cache busting..."

if [ -f "$THEME_DIR/styles.css" ]; then
    sed -i "1s/.*/\/* Chicago Booth Theme - Cache Bust: $TIMESTAMP *\//" "$THEME_DIR/styles.css"
    echo "Updated styles.css with timestamp: $TIMESTAMP"
fi

if [ -f "$THEME_DIR/.htaccess" ]; then
    sed -i "s/chicago-booth-v[0-9.]*/chicago-booth-v$TIMESTAMP/g" "$THEME_DIR/.htaccess"
    echo "Updated .htaccess ETag with timestamp: $TIMESTAMP"
fi

echo "Theme cache busting complete."
echo "Restart the ondemand container to apply Dex theme changes:"
echo "  docker restart ondemand"
