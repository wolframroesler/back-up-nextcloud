#!/bin/bash
# Encrypted backup of local Nextcloud to remote machine via rsync via ssh
# by Wolfram Rösler 2018-07-08

# Check if we're still running
PID=/var/run/cloudbackup.pid
if [ -f $PID ];then
    if kill -0 $(<$PID) &>/dev/null;then
        echo "Backup is still running"
        exit 0
    fi
fi
echo $$ >$PID

# Encryption key file
BASE=/home/yourname
export ENCFS6_CONFIG=$BASE/encfs6.xml

# Make the encrypted version of our local data
MNT=/mnt/nextcloud-encrypted
mkdir -p $MNT || exit
echo "Mounting $MNT"
umount $MNT 2>/dev/null
encfs --stdinpass --reverse /var/www/nextcloud/data $MNT <<<'your encfs password' || exit

# Go
echo
echo "Backing up"
echo
rm -f $BASE/backup-{begin,end,log}.txt
date >$BASE/backup-begin.txt
rsync -a -v -e "ssh -p23 -i /home/yourname/.ssh/id_rsa" \
    --log-file=$BASE/backup.log \
    --partial --progress --stats \
    $MNT \
    "u123456@u123456.your-storagebox.de:nextcloud"
date >$BASE/backup-end.txt

# Unmount it
echo
echo "Umounting"
umount $MNT

# Finish
rm $PID
echo
echo "Done."
