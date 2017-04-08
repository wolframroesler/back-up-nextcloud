#!/bin/bash

# Backups go here
BASE=~/cloud-backup

for user in linus;do

	echo "Backing up $user"

	DIR=$BASE/$user
	mkdir -p $DIR || exit

	umount /mnt/$user &>/dev/null
	mount /mnt/$user || exit

	rdiff-backup --terminal-verbosity 5 /mnt/$user $DIR || exit
	
	umount /mnt/$user

	echo
done
