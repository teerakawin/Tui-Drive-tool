# Tui-Drive-tool

Tui-Drive-tool is a tool that does drive stuff based on whiptail dialog menus for quick and safe disk management. It turns complex, dangerous terminal commands into a simple, automated interface.

## [!] Features
* **Automated Full Format:** Wipe drives, set GPT/MBR tables, and create file systems (ExFAT, EXT4, FAT32, NTFS).
* **OS Flashing:** Safely burn bootable Linux `.iso` images using the `dd` core engine.
* **Manual Layouts:** Instantly drops into `cfdisk` for custom partition sizing.
* **Storage Protection:** Includes optional built-in LUKS volume encryption.
* **Safety Lock:** Automatically hides and blocks your active root (`/`) system drive from accidental deletion.

## [!] Requirements
Ensure you have the following system utilities installed (most are built-in):
`lsblk`, `dd`, `parted`, `cfdisk`, `cryptsetup`, `whiptail`

## [!] Install and quick setup
1. Clone this repository.
   ```bash
   https://github.com/teerakawin/Tui-Drive-tool.git
   ```
2. Grant execution permissions:
   ```bash
   chmod +x tui_drive_tool.sh tui_backend.sh
   ```
3. Launch the utility with root privileges:
   ```bash
   sudo ./tui_drive_tool.sh
   ```
