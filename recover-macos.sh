#!/bin/bash
# Recover files from encrypted remote backup -- Mac version
# by Wolfram Rösler 2018-07-27

# Mount point for encrypted remote files (WebDAV mount)
ENC=/Volumes/u123456.your-storagebox.de
if [ ! -d $ENC ];then
    echo "In Finder, press ⌘ K and mount $ENC."
    exit 1
fi

# Encryption key file
export ENCFS6_CONFIG=/path/to/.encfs6.xml

# Mount point for decrypted backup
DEC=/Volumes/nextcloud-decrypted

# Umount first just to be sure
umount $DEC &>/dev/null

# Decrypt
mkdir -p $DEC || exit
encfs --public --stdinpass $ENC/nextcloud/nextcloud-encrypted $DEC <<<'your encfs password' || exit

# Open the decrypted files in Finder
open $DEC
read -p "Press Enter to unmount the recovery files:"

# Unmount everything
umount $DEC
umount $ENC
