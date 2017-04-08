#!/bin/bash

# Backups go here
BASE=~/cloud-backup

for user in linus;do
	echo "Backing up $user"

	# Make the destination directory
	DIR=$BASE/$user
	mkdir -p $DIR || exit

	# Mount the WebDAV directory (umount first in case it's already mounted)
	umount /mnt/$user &>/dev/null
	mount /mnt/$user || exit

	# Find the file with exclude patterns
	EXCLUDE=$DIR/exclude
	[ -f $EXCLUDE ] || EXCLUDE=/dev/null

	# Do it
	rdiff-backup --exclude-filelist $EXCLUDE --terminal-verbosity 5 /mnt/$user $DIR || exit
	
	# Unmount the WebDAV directory
	umount /mnt/$user

	echo
done
