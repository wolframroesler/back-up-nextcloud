#!/bin/bash
# Back up WebDAV mounts to local harddisk
# by Wolfram Rösler 2017-04-08

# Backups go here
BASE=~/cloud-backup

# Get user list from fstab file. Process users in a different order each time
# to have equal probability of one user not being backed up because of another
# user failing. Remember that a failed backup can lead to a very lengthy
# "regression" (rdiff-backup fetching all files anew from the cloud).
grep webdav /etc/fstab | cut -f2 -d' ' | cut -f3 -d/ | shuf | while read user;do

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

	# Now do the actual backup. Some log output goes to stdout, more
	# detailed logs go to $DIR/rdiff-backup-data/backup.log.
	rdiff-backup --exclude-filelist $(dirname $0)/exclude.txt --verbosity 6 --terminal-verbosity 3 /mnt/$user $DIR || exit
	
	# Unmount the WebDAV directory
	umount /mnt/$user
done 2>&1 | tee /tmp/cloud-backup.out
