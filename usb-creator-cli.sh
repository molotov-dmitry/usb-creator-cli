#!/bin/bash

ROOT_PATH="$(cd "$(dirname "$0")" && pwd)"
cd "${ROOT_PATH}" || exit 1

#### ===========================================================================
#### ===========================================================================
#### ===========================================================================

### Launching as root ==========================================================

if [[ $(id -u) -ne 0 ]]
then
    echo 'Launching as root'
    sudo bash $0 $@
    exit $?
fi

### Install required packages ==================================================

export DEBIAN_FRONTEND=noninteractive apt install -y syslinux mtools genisoimage beep > /dev/null

### Set variables ==============================================================

iso="$1"
label="$2"

usb="/dev/disk/by-label/${label}"

isodir="/tmp/media/${label}-iso"
usbdir="/tmp/media/${label}-usb"

### Check input ================================================================

if [[ $(file -biL "$usb" | cut -d ';' -f 1) != "inode/blockdevice" ]]
then
    echo "Error: USB disk '${label}' not found" >&2
fi

if ! isoinfo -d -i "${iso}" >/dev/null 2>&1
then
    echo "Error: ISO image '${iso}' not found" >&2
fi

### Mount ISO and USB ==========================================================

mkdir -p "${isodir}" > /dev/null
mkdir -p "${usbdir}" > /dev/null

umount -l "${usbdir}" > /dev/null
umount -l "$usb" > /dev/null

mount "$usb" "${usbdir}" -o rw,uid=$(id -u $USER),gid=$(id -g $USER) > /dev/null

umount -l "${isodir}" > /dev/null
umount -l "$iso" > /dev/null
mount -o loop "$iso" "${isodir}" > /dev/null

### Clear USB ==================================================================

find "${usbdir}" -mindepth 1 -delete > /dev/null

### Copy files to USB ==========================================================

rsync -ra -LK -pE --info=progress2 --exclude 'ubuntu' "${isodir}/" "${usbdir}/"

if [[ -d "${isodir}/EFI/BOOT" && ! -e "${isodir}/EFI/BOOT/bootia32.efi" ]]
then
    wget https://github.com/jfwells/linux-asus-t100ta/raw/master/boot/bootia32.efi -O "${isodir}/EFI/BOOT/bootia32.efi"
fi

### Sync =======================================================================

sync

### Unmount ====================================================================

umount -l "${usbdir}" > /dev/null
umount -l "$usb" > /dev/null
umount -l "${isodir}" > /dev/null
umount -l "$iso" > /dev/null

### Beep at finish =============================================================

beep -f 3000 -l 125 -r 2 -d 125

