#!/bin/bash

# Update Theme Cache Busting Script
# This script adds timestamps to theme files to force browser cache refresh

THEME_DIR="themes/hpc-coop"
TIMESTAMP=$(date +%s)

echo "Updating theme cache busting..."

# Update CSS file with timestamp
if [ -f "$THEME_DIR/styles.css" ]; then
    # Add timestamp to CSS file comment
    sed -i "1s/.*/\/* HPC-COOP Theme - Cache Bust: $TIMESTAMP *\//" "$THEME_DIR/styles.css"
    echo "✅ Updated styles.css with timestamp: $TIMESTAMP"
fi

# Update .htaccess ETag with timestamp
if [ -f "$THEME_DIR/.htaccess" ]; then
    sed -i "s/hpc-coop-v[0-9.]*/hpc-coop-v$TIMESTAMP/g" "$THEME_DIR/.htaccess"
    echo "✅ Updated .htaccess ETag with timestamp: $TIMESTAMP"
fi

echo "🎨 Theme cache busting complete!"
echo "💡 Restart OpenOnDemand container to apply changes:"
echo "   docker-compose restart ondemand" 