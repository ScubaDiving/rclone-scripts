
# Unraid Dropbox-to-Nextcloud Sync with Versioning

A robust bash script for Unraid users to perform a **one-way sync** from Dropbox to a Nextcloud AIO instance. This script includes automated versioning (archiving), permission management for Nextcloud AIO, and native Unraid GUI notifications.

## 🌟 Features
- **One-Way Sync:** Keeps your Nextcloud updated with Dropbox without deleting local files.
- **Automated Versioning:** Uses rclone's `--backup-dir` to move modified files to a dated archive instead of overwriting them.
- **AIO Compatibility:** Automatically handles the `UID 33` (www-data) permissions required by Nextcloud AIO.
- **Instant UI Refresh:** Triggers an `occ files:scan` so files appear in Nextcloud immediately.
- **Native Notifications:** Sends status alerts directly to the Unraid dashboard.

---

## 📋 Prerequisites

1. **Unraid OS** with the **User Scripts** plugin installed.
2. **rclone** installed via the Unraid App Store (rclone plugin).
3. **Nextcloud AIO** (All-in-One) Docker container running.

---

## 🛠️ Step 1: Configure Rclone (Persistent)

By default, Unraid stores rclone configs in RAM, which vanish on reboot. Follow these steps to make your Dropbox connection persistent.

1. Open the **Unraid Terminal**.
2. Run the configuration wizard:
   ```bash
   rclone config

    ```

3. Create a new remote named `dropbox-personal` (or your preferred name) and follow the OAuth login steps.
4. **Crucial:** Move the config file to your flash drive so it survives reboots:
```bash
mkdir -p /boot/config/plugins/rclone/
mv /root/.config/rclone/rclone.conf /boot/config/plugins/rclone/rclone.conf

```



---

## 📝 Step 2: The Script

1. Go to **Settings** > **User Scripts** on Unraid.
2. Click **Add New Script** and name it `Sync_Dropbox_Personal`.
3. Paste the following code:

```bash
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
chown -R 33:33 "/mnt/user/nextcloud/$NC_USER/files/Dropbox"
chown -R 33:33 "/mnt/user/nextcloud/$NC_USER/files/Dropbox_Archive"

# 6. Refresh Nextcloud AIO
echo "Refreshing Nextcloud Database..."
docker exec --user www-data nextcloud-aio-nextcloud php /var/www/html/occ files:scan --path="/$NC_USER/files/Dropbox"
docker exec --user www-data nextcloud-aio-nextcloud php /var/www/html/occ files:scan --path="/$NC_USER/files/Dropbox_Archive"

# 7. Notification: Finished
/usr/local/emhttp/plugins/dynamix/scripts/notify -s "Dropbox Sync" -d "One-way copy and Nextcloud scan completed successfully @ $(date +%H:%M:%S)."

echo "Sync and Versioning Complete at $(date)"

```

---

## 📂 Step 3: Folder Structure Setup

Ensure your Nextcloud share is correctly mapped. The script assumes your data is located at:
`/mnt/user/nextcloud/[user]/files/`

If you have multiple Dropbox accounts, simply create a second script, change the `SOURCE` name to your second rclone remote, and update the `DESTINATION` to a different folder (e.g., `/Dropbox_Work`).
Make sure to create both remotes in rclone together, then move the configuration file to persistent storage as described above in 1.4.

---

## ⏰ Step 4: Scheduling

In the **User Scripts** dashboard, set the schedule for your script:

* **Daily:** Runs once every night.
* **Custom:** Use `0 */6 * * *` to run every 6 hours.

---

## ⚠️ Troubleshooting

* **Scan shows 0 files:** Ensure the `NC_USER` variable matches your Nextcloud login exactly (case-sensitive).
* **Permission Denied:** Ensure your Nextcloud share is accessible and the script is running as `root` (default for User Scripts).
* **Container Name:** If your Nextcloud AIO container is not named `nextcloud-aio-nextcloud`, update the `docker exec` line in the script to match your container name.

---

*Created with the help of Gemini - Capable and genuinely helpful AI thought partner.*
