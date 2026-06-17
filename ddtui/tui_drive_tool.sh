#!/bin/bash

verify_dependencies() {
    local missing=()
    for cmd in lsblk dd parted cfdisk mkfs.exfat mkfs.vfat mkfs.ext4 mkfs.ntfs cryptsetup; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        whiptail --title "Missing Requirements" --msgbox "Please install: ${missing[*]}" 10 60
        exit 1
    fi
}

main_menu() {
    if [ "$EUID" -ne 0 ]; then
        whiptail --title "Sudo Needed" --msgbox "Launch using root permissions (sudo)!" 8 50
        exit 1
    fi
    
    verify_dependencies

    while true; do
        MAP_DATA=$(lsblk -rn -o NAME,SIZE,TYPE,MOUNTPOINT | awk '$3=="disk" && $4!="/" && $4!="/boot" {print "/dev/"$1, "["$2"]"}')
        
        if [ -z "$MAP_DATA" ]; then
            whiptail --title "No Disks" --msgbox "No external or non-root block devices detected." 8 50
            exit 0
        fi

        MENU_OPTIONS=()
        while read -r path size; do
            [ -n "$path" ] && MENU_OPTIONS+=("$path" "$size")
        done <<< "$MAP_DATA"

        TARGET_DISK=$(whiptail --title "Disk Target Selector" --menu "Select a physical disk:" 18 65 8 "${MENU_OPTIONS[@]}" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && { clear; echo "Goodbye!"; exit 0; }

        if lsblk -no MOUNTPOINT "$TARGET_DISK" | grep -E -q "^(/|/boot|/home)$"; then
            whiptail --title "EXCEPTION" --msgbox "Action Denied! System path detected." 8 60
            continue
        fi

        OP_MODE=$(whiptail --title "Operation Mode" --menu "Action for $TARGET_DISK:" 15 65 3 \
            "1" "Format Disk (Wipe and fully automate file system setup)" \
            "2" "Flash Bootable OS Image (dd an ISO layout to USB)" \
            "3" "Manual Partitioning (Launch interactive cfdisk manager)" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue

        if [ "$OP_MODE" == "3" ]; then
            clear
            echo "Launching cfdisk for $TARGET_DISK..."
            sleep 1
            cfdisk "$TARGET_DISK"
            whiptail --title "[OK] Finished" --msgbox "Changes locked into $TARGET_DISK." 8 50
            continue
        fi

        if [ "$OP_MODE" == "2" ]; then
            ISO_PATH=$(whiptail --title "Select OS Image" --inputbox "Enter full path to .iso file:" 10 60 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && continue

            if [ ! -f "$ISO_PATH" ]; then
                whiptail --title "File Error" --msgbox "[!] File does not exist: $ISO_PATH" 8 60
                continue
            fi

            if whiptail --title "[!!!] WARNING [!!!]" --yesno "Wipe $TARGET_DISK and flash $ISO_PATH?" 12 65; then
                clear
                echo "--> Clearing system mounts..."
                grep -q "$TARGET_DISK" /proc/mounts && umount -l "${TARGET_DISK}"* 2>/dev/null
                echo "--> Copying image layers..."
                dd if="$ISO_PATH" of="$TARGET_DISK" bs=4M status=progress oflag=sync
                sync
                whiptail --title "[OK] Succeeded" --msgbox "OS Image successfully written!" 8 45
            fi
            continue
        fi

        TABLE_TYPE=$(whiptail --title "Partition Table Layout" --menu "Choose table structure:" 15 60 3 \
            "gpt" "Modern GUID Table (Drives > 2TB & UEFI)" \
            "msdos" "Legacy MBR Layout (Old systems compatibility)" \
            "raw" "No partition table (Format raw block directly)" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue

        ENCRYPT="NO"
        if [ "$TABLE_TYPE" != "raw" ]; then
            whiptail --title "LUKS Encryption" --yesno "Encrypt this storage device with a password?" 10 55 && ENCRYPT="YES"
        fi

        FS_TYPE=$(whiptail --title "File System Format" --menu "Select native storage layout:" 16 65 4 \
            "exfat" "Cross-Platform (Windows/Mac/Linux)" \
            "vfat" "FAT32 Compatibility (Great for hardware tools)" \
            "ext4" "Linux Native (Supports advanced file permissions)" \
            "ntfs" "Windows Native Environment Allocation" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue

        if whiptail --title "[!!!] CRITICAL WARNING [!!!]" --yesno "WIPE ALL DATA ON $TARGET_DISK?\nTable: $TABLE_TYPE\nEncrypt: $ENCRYPT\nFS: $FS_TYPE" 14 65; then
            # We call our execution backend helper script here
            bash ./tui_backend.sh "$TARGET_DISK" "$TABLE_TYPE" "$ENCRYPT" "$FS_TYPE"
        else
            whiptail --title "Suspended" --msgbox "Operation canceled." 8 40
        fi
    done
}

main_menu
