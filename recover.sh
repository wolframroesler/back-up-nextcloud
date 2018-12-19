#!/bin/bash
# Recover files from encrypted remote backup -- Linux version
# by Wolfram Rösler 2018-07-14

# Mount point for encrypted remote files (WebDAV mount)
ENC=/mnt/nextcloud-recovery

# Mount point for decrypted backup
DEC=/mnt/nextcloud-decrypted

# Encryption key file
export ENCFS6_CONFIG=/home/yourname/.encfs6.xml

# Make sure both mount points exist
mkdir -p $ENC || exit
mkdir -p $DEC || exit

# Umount first just to be sure
umount $DEC &>/dev/null
umount $ENC &>/dev/null

# Mount the encrypted files (rely on /etc/fstab to provide the
# mount options and /etc/davfs2/secrets to provide the log-on
# credentials)
mount $ENC || exit

# Decrypt
encfs --public --stdinpass $ENC/nextcloud/nextcloud-encrypted $DEC <<<'your encfs password' || exit

# Invoke a shell in the decrypted directory
(
    cd $DEC || exit
    pwd
    echo "Press ^D to unmount the recovery files."
    sudo -u $SUDO_USER -s
)

# Unmount everything
umount $DEC
umount $ENC
