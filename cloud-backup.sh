#!/bin/bash

# Backups go here
BASE=~/cloud-backup


grep webdav /etc/fstab | cut -f2 -d' ' | cut -f3 -d/ | sort | while read user;do

	echo "Backing up $user"

	# Make the destination directory
	DIR=$BASE/$user
	mkdir -p $DIR || exit

	# Mount the WebDAV directory (umount first in case it's already mounted)
	umount /mnt/$user &>/dev/null
	mount /mnt/$user || exit

	# Do it
	rdiff-backup --force --exclude-filelist $BASE/exclude --terminal-verbosity 5 /mnt/$user $DIR || exit
	
	# Unmount the WebDAV directory
	umount /mnt/$user

	echo
done 2>&1 | tee /tmp/cloud-backup.out
