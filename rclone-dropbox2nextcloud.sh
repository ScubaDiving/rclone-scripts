#!/bin/bash

# 1. Variables
NC_USER="admin"
CONFIG_PATH="/boot/config/plugins/rclone/rclone.conf"
SOURCE="dropbox-personal:/"
DESTINATION="/mnt/user/nextcloud/$NC_USER/files/Dropbox"
TIMESTAMP=$(date +%Y-%m-%d)
BACKUP_DIR="/mnt/user/nextcloud/$NC_USER/files/Dropbox_Archive/$TIMESTAMP"

# 2. Check if Config exists
if [ ! -f "$CONFIG_PATH" ]; then
    /usr/local/emhttp/plugins/dynamix/scripts/notify -s "Dropbox Sync FAILED" -d "Rclone config not found at $CONFIG_PATH" -i "alert"
    exit 1
fi

# 3. Notification: Starting
/usr/local/emhttp/plugins/dynamix/scripts/notify -s "Dropbox Sync" -d "Starting one-way copy to Nextcloud..."

# 4. Perform the Copy with Versioning
echo "Starting One-Way Copy with Versioning..."
rclone --config "$CONFIG_PATH" copy "$SOURCE" "$DESTINATION" \
  --backup-dir "$BACKUP_DIR" \
  --update \
  --verbose

# 5. Permissions fix
# Note: Using 33:33 for Nextcloud AIO compatibility (www-data internal user)
chown -R 33:33 "/mnt/user/nextcloud/data/$NC_USER/files/Dropbox"
chown -R 33:33 "/mnt/user/nextcloud/data/$NC_USER/files/Dropbox_Archive"

# 6. Refresh Nextcloud AIO
echo "Refreshing Nextcloud Database..."
docker exec --user www-data nextcloud-aio-nextcloud php /var/www/html/occ files:scan --path="/$NC_USER/files/Dropbox"
docker exec --user www-data nextcloud-aio-nextcloud php /var/www/html/occ files:scan --path="/$NC_USER/files/Dropbox_Archive"

# 7. Notification: Finished
/usr/local/emhttp/plugins/dynamix/scripts/notify -s "Dropbox Sync" -d "One-way copy and Nextcloud scan completed successfully @ $(date +%H:%M:%S)."

echo "Sync and Versioning Complete at $(date)"