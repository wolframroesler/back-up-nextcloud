# How to back up Nextcloud data in Linux

So you have your Nextcloud, but how do you make a backup of the data stored in the cloud to your local Linux machine?

Of course, you could install the Nextcloud client software and let it sync everything to your machine, but that's not a backup. Imagine someone, somehow, removed a file from your backup: The Nextcloud client would immediately sync the removal over to your cloud, deleting the file there. Of course, Nextcloud will store the file for another 30 days, but then, is your Linux machine backing up the cloud data, or vice-versa? A backup should not be able to modify the data it is backing up.

This article describes how to back up your Nextcloud data to the harddisk of your Linux machine in a one-way fashion (changes to the backup will not be synced back into the cloud).

The Nextcloud client is not required. sudo permissions are required during set-up only.

## How it works

Mount your Nextcloud files using WebDAV. Then, use rsync to back them up to a local folder.

## Before you begin

The following instructions assume that you are familiar with Linux administration and with the Unix shell. Read and understand the shell commands before executing them. You will be editing crucial operating system files, messing them up can make your system fail to boot. Edit these files at your own risk. This is not a copy-and-paste-for-noobs recipe.

## Preparations

In the following, replace `myname` with the name of your Nextcloud user. If you want to back up more than one user, repeat appropriately for each of them.

```sh
$ sudo apt install ca-certificates
$ sudo apt install davfs2
$ sudo mkdir /mnt/myname
$ sudo usermod -aG davfs2 $USER
```

The last command (usermod) allows your Linux user to mount WebDAV shares. This allows the actual backup to run without root/sudo permissions. I had to reboot to activate this change (logging off might have been enough, though).

## Configure the WebDAV mount

The following examples assume that

* `mycloud.example.com` is your Nextcloud server
* `myname` is your Nextcloud user name
* `mypassword`is your Nextcloud password

If you want to back up more than one Nextcloud account, repeat accordingly.

First, add the following line to `/etc/fstab`:

```
https://mycloud.example.com/remote.php/webdav /mnt/myname davfs user,noauto,ro 0 0
```

Then, add the following to `/etc/davfs2/secrets`:

```
/mnt/myname myname mypassword
```

Note: Every user on your Linux machine can mount your Nextcloud files.

## Back up

To back up your Nextcloud data into directory `~/cloud-backup/myuser`:

```sh
$ mount /mnt/myuser
$ rsync --archive --partial /mnt/myuser ~/cloud-backup
$ umount /mnt/myuser
```

The shell script `cloud-backup.sh` in this repository does this in a more sophisticated way. It scans the names of the cloud users from the fstab file and mounts, backs up, and unmounts each user's files. Also, it supplies an exclusion file which specifies files that are not to be backed up. I use this for shared folders (stored once, visible to more than one account) which I want to back up only once, not once per user.

## Why not use rdiff-backup?

Instead of rsync, you could also use rdiff-backup (http://rdiff-backup.nongnu.org) to back up your cloud data, like so:

```sh
$ mount /mnt/myuser
$ rdiff-backup /mnt/myuser ~/cloud-backup/myuser
$ umount /mnt/myuser
```

rdiff-backup has some more sophisticated backup features compared to rsync, however it didn't work particularly well for me. Sometimes my backup failed (for example, due to a temporary loss of WLAN connectivity), after which rdiff-backup started a lenghty recovery operation during which it seemingly downloaded every single file again (not much fun with a Nextcloud of 140 GB and many thousands of files). Plain rsync proved to be much faster and more stable for me. Your milage may vary.

## Resources

Mounting WebDAV: https://wiki.ubuntuusers.de/WebDAV/

rsync: http://rsync.samba.org

---
*Wolfram Rösler • wolfram@roesler-ac.de • https://twitter.com/wolframroesler • https://github.com/wolframroesler*
