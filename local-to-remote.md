# How to back up a local Nextcloud to a remote server

So you set up your Nextcloud instance on your own Linux machine. Congratulations, you now own all your data, nobody else can do nasty things with it. Your cloud no longer is "someone else's computer". However, what happens to your data in case of a catastrophic failure? What if your harddisk crashes, destroying your Nextcloud machine? Of  course, you've synced your files to your work computer, after all that's what Nextcloud is all about. But what if your apartment burns down, with the Nextcloud server and your work computer in it?

What you want is a backup of your data on a remote machine. That could be your work computer (if your employer allows it), a friend's computer (if he doesn't mind the power and bandwitdh consumption), or a storage server you rented from a service provider. In either case, the remote machine is in someone else's hands, and you don't want them to be able to access your files. So, we're looking for an encrypted backup.

This article explains how to do it. I'm using a Hetzner Storage Box (https://www.hetzner.de/storage-box) which gives you several hundred gigabytes of storage which you can acccess by various means, including rsync over SSH which is what we're going to use in this article.

## Set up ssh

Set up your remote machine to accept rsh connections from your local machine. How to do this is beyond the scope if this article, however here's how to copy your local ssh public key to the Hetzner Storage Box (replace your user name appropriately):

```sh
$ cd ~/.ssh
$ echo -e "mkdir .ssh \n chmod 700 .ssh \n put id_rsa.pub .ssh/authorized_keys \n chmod 600 .ssh/authorized_keys" | sftp u123456@u123456.your-storagebox.de
```

## Set up the encrypted file system

On your local machine, install the "encfs" package:

```sh
$ sudo apt-get install encfs
```

Create the mount point for the encrypted file system:

```sh
$ sudo mkdir /mnt/nextcloud-encrypted
```

Then, initialize the encryption like this:

```sh
$ encfs --stdinpass --reverse /var/www/nextcloud/data /mnt/nextcloud-encrypted
```

This will ask you if you want to do extended or paranoid stuff. Just press Enter. Then, it'll ask you for a password. Enter a secure password (for example, use `pwgen` to create one) and store it in a safe place.

It also created the encryption key file, `.encfs6.xml`, in the `/var/www/nextcloud/data` directory. Make a backup of that file. To decrypt your backup, you'll need both the key file and the password.

You can now have a look at the encrypted version of your Nextcloud files. It'll look somehow like this:

```sh
$ sudo ls -l /mnt/nextcloud-encrypted
drwxr-xr-x  4 www-data www-data   4096 Jun 16 17:05 7KXgpNAfxP7JfWVr32JiW964SDU4K,SZKv7XMniCNliIz-
drwxr-xr-x  2 www-data www-data   4096 Jun 16 17:05 bIR3WrZyEQAMz0xYUBoy6dKo
-rw-r--r--  1 www-data www-data  12349 Jun 16 17:05 gqDqwBKCthaZjdE1JaDKOLpG
drwxr-xr-x  6 www-data www-data   4096 Jul  2 16:14 H363-hxkwz2y-eisFw7V,pHd
-rw-r--r--  1 www-data www-data    324 Jun 16 17:05 IoMqqgHXyCvi5N-gRdAdr6D5
-rw-r--r--  1 www-data www-data      0 Jun 16 17:05 K19KtnWAKuTStxHjHlQzVS7O
drwxr-xr-x  6 www-data www-data   4096 Jul  8 14:56 Kt9kFGR9sGnpA3ZQLvecPgEE
-rw-r-----  1 www-data www-data 815109 Jul  8 14:51 KtoutrE2SXJF6dtm63K-YekW
drwxr-xr-x  5 www-data www-data   4096 Jul  7 11:16 LqqeraF-,c1S7gQwrVwh4aB4
drwxr-xr-x 10 www-data www-data   4096 Jun 10 18:38 P1XUHxjwDFxSCENwb-hgcOS6RK7ADLDD0g,WelVZqTWSk1
-rw-r--r--  1 www-data www-data      0 Jun 16 17:05 wCC4iTqF0FCM9HL7EPPp62uP
```

## Back up

Copy following to file `encrypted-backup.sh` somewhere on your local machine. Edit it to match your local configuration, and put the encryption password (which you entered when executing `encfs` above) into it.

```sh
MNT=/mnt/nextcloud-encrypted
mkdir -p $MNT || exit
umount $MNT 2>/dev/null
encfs --stdinpass --reverse /var/www/nextcloud/data $MNT <<<'your encfs password' || exit
rsync -a -v -e "ssh -p23 -i /home/yourname/.ssh/id_rsa" \
    --log-file=/var/log/encrypted-backup.log \
    --partial --progress --stats \
    $MNT \
    "u123456@u123456.your-storagebox.de:nextcloud"
umount $MNT
```

In the script, when invoking rsync, use `-e` to specify the remote server's ssh port and name of your local ssh private key file. The latter is necessary because we'll be invoking this file as root.

Then, run the backup:

```sh
$ sudo bash encrypted-backup.sh
```

The backup process is logged in `/var/log/encrypted-backup.log` and also displayed on screen. Depending how much data there is in your Nextcloud, the first backup will take a considerable time, but later backups will only upload changed and new files.

You may want to set up automatic backups. For example, to run the backup script every night at 1:00:

```ssh
$ sudo crontab -e
0 1 * * * bash /path/to/encrypted-backup.log >/var/log/encrypted-backup.out 2>&1
```

File `encrypted-backup.sh` in this repository is a slightly more sophisticated version of the above script, with the following improvements:

* The encryption key file is not stored in www/nextcloud/data but in the user's home directory.
* Log files with start date, end date, and rsync log are created in the user's home directory.
* The script checks if it's already running, and terminates immediately if it is. That makes it possible to execute it more frequently (e. g. I've set up cron to run it once per hour).

## Recovery

To be done.

## More information

This article got me started with encfs: http://jc.coynel.net/2013/08/secure-remote-backup-with-openvpn-rsync-and-encfs/

Storage Box FAQ: https://wiki.hetzner.de/index.php/Backup_Space_SSH_Keys/en

I'm not affiliated with Hetzer in any way beside being a satisfied customer. Nobody's paying me for my endorsement of their product, unfortunately.

---
*Wolfram Rösler • wolfram@roesler-ac.de • https://twitter.com/wolframroesler • https://gitlab.com/wolframroesler*
