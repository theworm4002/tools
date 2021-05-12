#!/usr/bin/env bash

TODAY="$(date +'%Y_%m_%d')"

BACKUP_NAME="ts_backup_${TODAY}"
BACKUP_FOLDER="/tmp/${BACKUP_NAME}"
BACKUP_ARCHIVE="${BACKUP_FOLDER}.zip"
BACKUP_PUBLIC_KEY="${1}"
MARIADB_CONTAINER_NAME="${2}"
TS_DATA_FOLDER="${3}"
RCLONE_REMOTE="${4}"
RCLONE_REMOTE_FOLDER="ts_backups"

echo "Creating backup folder..."
mkdir -p "${BACKUP_FOLDER}"
echo ""

echo "Dumping TS database..."
docker exec "${MARIADB_CONTAINER_NAME}" sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > "${BACKUP_FOLDER}/ts_db_backup_${TODAY}.sql"
echo ""

echo "Copying TS data folder to backup folder..."
rsync -a "${TS_DATA_FOLDER}" "${BACKUP_FOLDER}"
echo ""

echo "Zipping backup folder..."
7z a "${BACKUP_ARCHIVE}" "${BACKUP_FOLDER}"
echo ""

echo "Encrypting backup archive..."
python3 -c 'from plasm import encrypt; encrypt.encrypt_file("'"${BACKUP_ARCHIVE}"'", "'"${BACKUP_PUBLIC_KEY}"'", remove_input_file=True)'
echo ""

echo "Copying encrypted backup archive to cloud..."
rclone copy "${BACKUP_ARCHIVE}.crypt" "${RCLONE_REMOTE}:${RCLONE_REMOTE_FOLDER}/"
echo ""

echo "Removing backup folder..."
rm -rf "${BACKUP_FOLDER}"
echo ""
