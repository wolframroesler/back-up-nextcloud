#!/bin/bash
# Back up WebDAV mounts to local harddisk
# by Wolfram Rösler 2017-04-08

# Backups go here
BASE=~/cloud-backup

# Get user list from fstab file
grep webdav /etc/fstab | cut -f2 -d' ' | cut -f3 -d/ | sort | while read user;do

	# Show the starting message
	echo
	echo "$(date) Backing up $user"
	echo

	# Make the destination directory
	DIR=$BASE/$user
	mkdir -p $DIR || exit

	# Mount the WebDAV directory (umount first in case it's already mounted)
	umount /mnt/$user &>/dev/null
	mount /mnt/$user || exit

	# Now do the actual backup
	rdiff-backup --force --exclude-filelist $(dirname $0)/exclude.txt --verbosity 7 --terminal-verbosity 3 /mnt/$user $DIR || exit
	
	# Unmount the WebDAV directory
	umount /mnt/$user
done 2>&1 | tee /tmp/cloud-backup.out
