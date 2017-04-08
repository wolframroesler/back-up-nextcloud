#!/bin/bash

# Backups go here
BASE=~/cloud-backup

for user in linus;do

	echo "Backing up $user"

	DIR=$BASE/$user
	mkdir -p $DIR || exit

	mount /mnt/$user || exit

	rdiff-backup --terminal-verbosity 9 /mnt/$user $DIR || exit
	
	umount /mnt/$user
done
