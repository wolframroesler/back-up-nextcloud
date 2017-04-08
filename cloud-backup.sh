#!/bin/bash

# Backups go here
BASE=~/cloud-backup

for user in linus jacky wolfram;do
	echo "Backing up $user"

	# Make the destination directory
	DIR=$BASE/$user
	mkdir -p $DIR || exit

	# Mount the WebDAV directory (umount first in case it's already mounted)
	umount /mnt/$user &>/dev/null
	mount /mnt/$user || exit

	# Do it
	rdiff-backup --exclude-filelist $BASE/exclude --terminal-verbosity 5 /mnt/$user $DIR || exit
	
	# Unmount the WebDAV directory
	umount /mnt/$user

	echo
done
