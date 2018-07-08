#!/bin/bash
# Encrypted backup of local Nextcloud to remote machine via rsync via ssh
# by Wolfram Rösler 2018-07-08

MNT=/mnt/nextcloud-encrypted

echo "Mounting"
mkdir -p $MNT || exit
umount $MNT 2>/dev/null
encfs --stdinpass --reverse /var/www/nextcloud/data $MNT <<<'your encfs password' || exit

echo
echo "Backing up"
echo
rsync -a -v -e "ssh -p23 -i /home/yourname/.ssh/id_rsa" \
    --log-file=/var/log/encrypted-backup.log \
    --partial --progress --stats \
    $MNT \
    "u123456@u123456.your-storagebox.de:nextcloud"

echo
echo "Umounting"
umount $MNT

echo
echo "Done."
