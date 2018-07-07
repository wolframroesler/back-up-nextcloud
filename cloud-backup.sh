#!/bin/bash
# Back up WebDAV mounts to local harddisk
# by Wolfram Rösler 2017-04-08

# Backups go here
BASE=~/cloud-backup
mkdir -p $BASE || exit

# rsync log file
LOG=/tmp/cloud-backup.log
rm -f $LOG

# Get user list from fstab file
grep webdav /etc/fstab | cut -f2 -d' ' | cut -f3 -d/ | shuf | while read user;do

	# Show the starting message
	echo
	echo "$(date) Backing up $user"
	echo

	# Mount the WebDAV directory (umount first in case it's already mounted)
	umount /mnt/$user &>/dev/null
	mount /mnt/$user || exit

	# Now do the actual backup
	rsync -a -v --exclude-from="$(dirname $0)/exclude.txt" /mnt/$user $BASE --log-file=$LOG --partial --progress --stats || exit
	
	# Unmount the WebDAV directory
	umount /mnt/$user
done 2>&1 | tee /tmp/cloud-backup.out
