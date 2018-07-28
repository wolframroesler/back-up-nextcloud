# How to back up a local Nextcloud to a remote server

So you set up your Nextcloud instance on your own Linux machine. Congratulations, you now own all your data, nobody else can do nasty things with it. Your cloud no longer is "someone else's computer". However, what happens to your data in case of a catastrophic failure? What if your harddisk crashes, destroying your Nextcloud machine? Of  course, you've synced your files to your work computer, after all that's what Nextcloud is all about. But what if your apartment burns down, with the Nextcloud server and your work computer in it?

What you want is a backup of your data on a remote machine. That could be your work computer (if your employer allows it), a friend's computer (if he doesn't mind the power and bandwitdh consumption), or a storage server you rented from a service provider. In either case, the remote machine is in someone else's hands, and you don't want them to be able to access your files. So, we're looking for an encrypted backup.

This article explains how to do it. I'm using a Hetzner Storage Box (https://www.hetzner.de/storage-box) which gives you several hundred gigabytes of storage which you can acccess by various means, including WebDAV and rsync over SSH which is what we're going to use in this article.

## Set up ssh

Set up your remote machine to accept rsh connections from your local machine. How to do this is beyond the scope if this article, however here's how to copy your local ssh public key to the Hetzner Storage Box (replace your user name appropriately):

```sh
$ cd ~/.ssh
$ echo -e "mkdir .ssh \n chmod 700 .ssh \n put id_rsa.pub .ssh/authorized_keys \n chmod 600 .ssh/authorized_keys" | sftp u123456@u123456.your-storagebox.de
```

Don't forget to enable SSH access (and WebDAV, while you're at it, which we'll use for recovery) in your Storage Box configuration (on the Hetzner Robot page).

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
$ sudo encfs --stdinpass --reverse \
  /var/www/nextcloud/data \
  /mnt/nextcloud-encrypted
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
* The script checks if it's already running, and terminates immediately if it is. That makes it possible to execute it more frequently, even when the previous instance is still running (e. g. I've set up cron to run it once per hour).

## Recovery

For recovery of our backed up Nextcloud files we first mount the remote backup via WebDAV (giving us access to the encrypted files on the remote server), and then use `encfs` to create an unencrypted version of these files on another mount point. Again, how to make a remote file  server available through WebDAV is beyond the scope of this article, and we're using the Hetzner Storage Box as an example.

### Mounting encrypted files

First create the mount point:

```sh
$ sudo mkdir /mnt/nextcloud-recovery
```

Then put the following into your `/etc/fstab`:

```
https://u123456.your-storagebox.de /mnt/nextcloud-recovery davfs user,noauto,ro,dir_mode=555,file_mode=444,_netdev 0 0
```

Note that we're mounting in read-only mode to avoid inadvertant changes of the remote files.

Also, put the remote backup's user name and password into `/etc/davfs2/secrets`:

```
/mnt/nextcloud-recovery u123456 YourWebDAVPassword
```

Now you can mount the encrypted files:

```sh
$ sudo mount /mnt/nextcloud-recovery
```

This is what it looks like:

```
$ ls -l /mnt/nextcloud-recovery/nextcloud/nextcloud-encrypted/
insgesamt 1112
dr-xr-xr-x  4 root root       0 Jun 16 17:05 7KXgpNAfxP7JfWVr32JiW964SDU4K,SZKv7XMniCNliIz-
dr-xr-xr-x  2 root root       0 Jun 16 17:05 bIR3WrZyEQAMz0xYUBoy6dKo
-r--r--r--  1 root root   12349 Jun 16 17:05 gqDqwBKCthaZjdE1JaDKOLpG
dr-xr-xr-x  6 root root       0 Jul  2 16:14 H363-hxkwz2y-eisFw7V,pHd
-r--r--r--  1 root root     324 Jun 16 17:05 IoMqqgHXyCvi5N-gRdAdr6D5
-r--r--r--  1 root root       0 Jun 16 17:05 K19KtnWAKuTStxHjHlQzVS7O
dr-xr-xr-x  6 root root       0 Jul  8 14:56 Kt9kFGR9sGnpA3ZQLvecPgEE
-r--r--r--  1 root root 1125158 Jul 14 11:40 KtoutrE2SXJF6dtm63K-YekW
dr-xr-xr-x  6 root root       0 Jul  9 20:52 LqqeraF-,c1S7gQwrVwh4aB4
dr-xr-xr-x 10 root root       0 Jun 10 18:38 P1XUHxjwDFxSCENwb-hgcOS6RK7ADLDD0g,WelVZqTWSk1
-r--r--r--  1 root root       0 Jun 16 17:05 wCC4iTqF0FCM9HL7EPPp62uP
```

Very similar to the encrypted data we're rsyncing to the remote backup server, however this time we are looking at what's already on the remote.

### Decrypting the encrypted backup

First of all we need another mount point:

```sh
$ sudo mkdir /mnt/nextcloud-decrypted
```

into which we now let `encfs` do its magic:

```sh
$ sudo ENCFS6_CONFIG=/var/www/nextcloud/data/.encfs6.xml \
  encfs --public --stdinpass \
  /mnt/nextcloud-recovery/nextcloud/nextcloud-encrypted \
  /mnt/nextcloud-decrypted \
  <<<'your encfs password'
```

Note that the encfs root directory (where the encrypted files are) isn't the WebDAV mount itself (`/mnt/nextcloud-recovery`) but a subdirectory within in, namely the one that contains the actual encrypted files. This of course depends on which directory your remote storage actually provides WebDAV access to.

`--public` makes the decrypted files visible to non-root users. You may leave it away but then you'll have to `sudo -s` or similar to access them.

Now, at last, you can recover your files:

```sh
$ cd /mnt/nextcloud-decrypted
$ ls -l
dr-xr-xr-x  6 root root    0 Jul  8 14:56 admin
dr-xr-xr-x 10 root root    0 Jun 10 18:38 appdata_ocdj1xdf31l8
dr-xr-xr-x  2 root root    0 Jun 16 17:05 files_external
-r--r--r--  1 root root    0 Jun 16 17:05 index.html
dr-xr-xr-x  6 root root    0 Jul  9 20:52 itunes
-r--r--r--  1 root root 1,1M Jul 14 11:40 nextcloud.log
-r--r--r--  1 root root  13K Jun 16 17:05 updater.log
dr-xr-xr-x  4 root root    0 Jun 16 17:05 updater-ocdj1xdf31l8
dr-xr-xr-x  6 root root    0 Jul  2 16:14 wolfram
```

### Putting it all together

Shell script `recover.sh` in this repository first mounts the remote encrypted files, then mounts the decrypted files, then puts the user into an interactive shell to access them. When the user exits this shell, everything is unmounted. It also shows how to use an alternate location for the encryption key file.

Here's how to use it:

```sh
$ sudo bash recover.sh
/mnt/nextcloud-decrypted
Press ^D to unmount the recovery files.
$ ls -l
total 1112
dr-xr-xr-x  6 root root       0 Jul  8 14:56 admin
dr-xr-xr-x 10 root root       0 Jun 10 18:38 appdata_ocdj1xdf31l8
dr-xr-xr-x  2 root root       0 Jun 16 17:05 files_external
-r--r--r--  1 root root       0 Jun 16 17:05 index.html
dr-xr-xr-x  6 root root       0 Jul  9 20:52 itunes
-r--r--r--  1 root root 1125158 Jul 14 11:40 nextcloud.log
dr-xr-xr-x  4 root root       0 Jun 16 17:05 updater-ocdj1xdf31l8
-r--r--r--  1 root root   12349 Jun 16 17:05 updater.log
dr-xr-xr-x  6 root root       0 Jul  2 16:14 wolfram
$ exit
/sbin/umount.davfs: waiting while mount.davfs (pid 16026) synchronizes the cache .. OK
```

### Validating the backup

Do the following to compare your complete Nextcloud to the contents of the backup. Note that this downloads and decrypts the entire backup, so be prepared for some considerable consumption of time and bandwidth. For best results, do this after a fresh run of `encrypted-backup.sh` and don't modify anything in your Nextcloud while it's running.

```sh
$ sudo bash recover.sh
/mnt/nextcloud-decrypted
Press ^D to unmount the recovery files.
$ sudo diff -rq /var/www/nextcloud/data /mnt/nextcloud-decrypted
```

You may wish to add something like `-x .DS_Store` to the `diff` command line if you're using a Mac.

## Recovery on a Mac

### Preparations

First, install the "brew" packet manager:

```sh
$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Second, use it to install `encfs`, the encrypted file system driver:

```sh
$ brew cask install osxfuse
$ brew install encfs
```

Contrary to what the former says, it works fine without a reboot.

### Mounting the encrypted files

To mount the encrypted files via WebDAV, press ⌘K in Finder. Enter the WebDAV address (e. g., `https://u123456.your-storagebox.de`) and your user name (`u123456`) and password. If you allow Finder to store user name and password in your key chain, you don't have to enter them the next time.

Your encrypted files are now available in `/Volumes/u123456.your-storagebox.de`.

### Decrypting the encrypted backup

Use the following to decrypt the files you mounted in the previous step:

```sh
$ mkdir -p /Volumes/nextcloud-decrypted
$ sudo ENCFS6_CONFIG=/path/to/.encfs6.xml \
  encfs --public --stdinpass \
  /Volumes/u123456.your-storagebox.de/nextcloud/nextcloud-encrypted \
  /Volumes/nextcloud-decrypted \
  <<<'your encfs password'
```

Now open Finder, press ⇧⌘G, and enter `/Volumes/nextcloud-decrypted` to browse the decrypted files. Or cd to this directory and acccess your files with the shell like real men do.

To unmount everything:

```sh
$ sudo umount /Volumes/nextcloud-decrypted
$ umount /Volumes/u123456.your-storagebox.de
```

Note that, unlike in Linux, this automatically removes the mount point.

### Putting it all together

Shell script `recover-macos.sh` in this repository mounts the encrypted files and opens a Finder window to browse them. Tailor the script to suit your needs, then invoke it like this:

```sh
$ sudo bash recover-macos.sh
```

Since mounting a WebDAV directory non-interactively is difficult on a Mac, the script requires the user to mount the encrypted files manually with Finder first (as described above). Both mounts (encrypted and decrypted files) are unmounted when the script ends.

## More information

This article got me started with encfs: http://jc.coynel.net/2013/08/secure-remote-backup-with-openvpn-rsync-and-encfs/

Storage Box ssh key handling: https://wiki.hetzner.de/index.php/Backup_Space_SSH_Keys/en

Storage Box WebDAV: https://wiki.hetzner.de/index.php/Storage_Boxes/en#WebDAV

Mounting WebDAV in Linux: https://gitlab.com/wolframroesler/snippets#mount-nextcloud

Mounting WebDAV in macOS: https://superuser.com/questions/699271/how-to-mount-webdav-filesystem-on-mac

Using EncFS in macOS: https://www.maketecheasier.com/install-encfs-mac/

I'm not affiliated with Hetzer in any way beside being a satisfied customer. Nobody's paying me for my endorsement of their product, unfortunately.

---
*Wolfram Rösler • wolfram@roesler-ac.de • https://twitter.com/wolframroesler • https://gitlab.com/wolframroesler*
