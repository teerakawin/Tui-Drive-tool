#!/bin/bash
# Dedicated Backend Processing Script

dev="$1"
table="$2"
crypt="$3"
fs="$4"
target_partition="$dev"

clear
echo "======================================================================"
echo "                 INITIATING DISK DESTRUCTION PIPELINE                  "
echo "======================================================================"
echo ""

echo "--> Clearing system mount flags..."
grep -q "$dev" /proc/mounts && umount -l "${dev}"* 2>/dev/null

echo "--> Running dd command over primary sector lines..."
dd if=/dev/zero of="$dev" bs=1M count=32 status=progress
sync

if [ "$table" != "raw" ]; then
    echo "--> Building a fresh [$table] partition framework mapping..."
    parted -s "$dev" mklabel "$table"
    
    echo "--> Allocating single contiguous primary partition..."
    parted -s -a optimal "$dev" mkpart primary 0% 100%
    sync
    sleep 2
    
    if [[ "$dev" == *nvme* || "$dev" == *mmcblk* ]]; then
        target_partition="${dev}p1"
    else
        target_partition="${dev}1"
    fi
fi

if [ "$crypt" == "YES" ]; then
    echo "--> Initializing LUKS Crypto Container configuration layer..."
    echo "Please enter a strong password below to seal the device container block."
    
    if ! cryptsetup luksFormat --type luks2 "$target_partition"; then
        whiptail --title "Execution Failure" --msgbox "[!] Failed to format security crypt container block." 8 50
        exit 1
    fi

    echo "--> Unlocking virtual crypto block engine mapping tunnel..."
    if ! cryptsetup open "$target_partition" secure_tui_vault; then
        whiptail --title "Execution Failure" --msgbox "[!] Failed to map crypt mapping pointer." 8 50
        exit 1
    fi
    target_partition="/dev/mapper/secure_tui_vault"
fi

echo "--> Creating native filesystem index arrays [$fs]..."
case "$fs" in
    "exfat") mkfs.exfat "$target_partition" ;;
    "vfat")  mkfs.vfat -F 32 -I "$target_partition" ;;
    "ext4")  mkfs.ext4 -F "$target_partition" ;;
    "ntfs")  mkfs.ntfs -f "$target_partition" ;;
esac

if [ "$crypt" == "YES" ]; then
    echo "--> Sealing cryptographic vault mappings safely..."
    sync && sleep 1
    cryptsetup close secure_tui_vault
fi

sync
whiptail --title "[OK] Pipeline Succeeded" --msgbox "Target Device completely restructured, partitioned, and formatted!" 10 60
