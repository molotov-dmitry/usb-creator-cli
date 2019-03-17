#!/bin/bash

shopt -s extglob

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

DEBIAN_FRONTEND=noninteractive apt-get install -y syslinux mtools genisoimage beep > /dev/null

### Getting parameters =========================================================

labels="@($(ls -1 "/dev/disk/by-label" | tr '\n' '|' | sed 's/|$//'))"
progress='--info=progress2'

while [[ $# -gt 0 ]]
do

    case "$1" in

    '--quiet')
        nobeep='y'
    ;;

    '--test')
        testonly='y'
    ;;


    '--no-progress')
        progress=''
    ;;

    '--notify')
        notify='y'
    ;;

    *.iso)
        iso="$1"
    ;;

    ${labels})
        label="$1"
    ;;

	*)
		echo "Unknown argument '${1}'"
	;; 

    esac

    shift

done

### Set variables ==============================================================

usb="/dev/disk/by-label/${label}"

isodir="/tmp/media/${label}-iso"
usbdir="/tmp/media/${label}-usb"

### Check input ================================================================

if [[ $(file -biL "$usb" | cut -d ';' -f 1) != "inode/blockdevice" ]]
then
    echo "Error: USB disk '${label}' not found" >&2
	exit 1
fi

if ! isoinfo -d -i "${iso}" >/dev/null 2>&1
then
    echo "Error: ISO image '${iso}' not found or not a valid ISO image" >&2
	exit 2
fi

#### Exit if test only flag is set =============================================

if [[ "$testonly" == 'y' ]]
then
    exit 0
fi

### Mount ISO and USB ==========================================================

mkdir -p "${isodir}"  > /dev/null
mkdir -p "${usbdir}"  > /dev/null

umount -l "${usbdir}" > /dev/null
umount -l "$usb"      > /dev/null

umount -l "${isodir}" > /dev/null
umount -l "$iso"      > /dev/null

### Mount ISO and USB ==========================================================

mount "$usb" "${usbdir}" -o rw,uid=$(id -u $USER),gid=$(id -g $USER) > /dev/null || exit 3
mount -o loop "$iso" "${isodir}" > /dev/null || exit 4

### Clear USB ==================================================================

find "${usbdir}" -mindepth 1 -delete > /dev/null

### Copy files to USB ==========================================================

rsync -ra -LK -pE ${progress} --exclude 'ubuntu' "${isodir}/" "${usbdir}/"

if [[ -d "${usbdir}/EFI/BOOT" && ! -e "${usbdir}/EFI/BOOT/bootia32.efi" ]]
then
    wget https://github.com/jfwells/linux-asus-t100ta/raw/master/boot/bootia32.efi -O "${usbdir}/EFI/BOOT/bootia32.efi" || exit 1
fi

### Sync =======================================================================

sync

### Unmount ====================================================================

umount -l "${usbdir}" > /dev/null
umount -l "$usb"      > /dev/null
umount -l "${isodir}" > /dev/null
umount -l "$iso" 	  > /dev/null

### Send notify ================================================================

if [[ "$notify" == 'y' ]]
then
    echo "usb-creator-gtk:$(basename "${iso}") write completed" | nc -b -w1 -u 255.255.255.255 14993
fi

### Beep at finish =============================================================

if [[ "$nobeep" != 'y' ]]
then
    beep -f 2050 -r 2 -d 100 -l 30
fi

