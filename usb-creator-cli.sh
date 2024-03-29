#!/bin/bash

shopt -s extglob

#### ===========================================================================
#### ===========================================================================
#### ===========================================================================

### Launching as root ==========================================================

if [[ $(id -u) -ne 0 ]]
then
    echo 'Launching as root'
    sudo bash $0 "$@"
    exit $?
fi

### Functions ==================================================================

notify()
{
    echo "$@" | nc -b -w1 -u 255.255.255.255 14993
}

error()
{
	local code="$1"
	local message="$2"

	if [[ "$notify" == 'y' ]]
	then
		notify "dialog-error:${message}"
	fi

    echo "Error: ${message}" >&2
	exit $code
}

### Getting parameters =========================================================

labels="@($(ls -1 "/dev/disk/by-label" | tr '\n' '|' | sed 's/|$//'))"
progress='--info=progress2'
check='y'

while [[ $# -gt 0 ]]
do

    case "$1" in

    '--beep')
        beep='y'
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
    
    '--no-check')
        check='n'
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

isodir="/tmp/media/${label,,}-iso"
usbdir="/tmp/media/${label,,}-usb"

### Check input ================================================================

if [[ $(file -biL "$usb" | cut -d ';' -f 1) != "inode/blockdevice" ]]
then
	error 1 "USB disk '${label}' not found"
fi

if ! isoinfo -d -i "${iso}" >/dev/null 2>&1
then
	error 2 "ISO image '${iso}' not found or not a valid ISO image"
fi

#### Exit if test only flag is set =============================================

if [[ "$testonly" == 'y' ]]
then
    exit 0
fi

### Mount ISO and USB ==========================================================

### Create directories for mount points ----------------------------------------

mkdir -p "${isodir}"  > /dev/null
mkdir -p "${usbdir}"  > /dev/null

### Unmount used mount points --------------------------------------------------

for point in "$usbdir" "$isodir"
do
    if mountpoint "$point" > /dev/null 2> /dev/null
    then
        umount "$point" || error 7 "Failed to unmount $point"
    fi
done

### Unmount USB device ---------------------------------------------------------

if grep "^$(realpath "$usb")[[:space:]]" /proc/mounts > /dev/null
then
    umount "$usb" || error 7 "Failed to unmount USB device $label"
fi

### Mount ISO and USB ==========================================================

if ! mount "$usb" "${usbdir}" -o rw,uid=$(id -u $USER),gid=$(id -g $USER) > /dev/null
then
	error 3 "$usb not mounted"
fi

if ! mount -o loop,ro "$iso" "${isodir}" > /dev/null
then
	error 4 "$iso not mounted"
fi

### Copy files to USB ==========================================================

rsync -ra --checksum -LK -pE ${progress} --exclude '/ubuntu' --exclude '/debian' --delete-before --ignore-errors --delete-excluded "${isodir}/" "${usbdir}/"

### Sync =======================================================================

sync

### Check data =================================================================

if [[ "$check" == 'y' ]]
then
    pushd "$isodir" > /dev/null || error 5 "Failed to cd to $isodir"
    md5sums="$(find -L -type f -exec md5sum {} \; 2>/dev/null)"
    popd > /dev/null || error 5 "Failed to cd to $OLDPWD"
    
    pushd "$usbdir" > /dev/null || error 5 "Failed to cd to $usbdir"
    if ! echo "${md5sums}" | md5sum -c --status
    then
        error 6 "Checksum validation failed"
    fi
    popd > /dev/null || error 5 "Failed to cd to $OLDPWD"
    
fi

### Unmount ====================================================================

### Unmount used mount points --------------------------------------------------

for point in "$usbdir" "$isodir"
do
    if mountpoint "$point" > /dev/null 2> /dev/null
    then
        umount "$point" || error 7 "Failed to unmount $point"
    fi
done

### Unmount USB device ---------------------------------------------------------

if grep "^$(realpath "$usb")[[:space:]]" /proc/mounts > /dev/null
then
    umount "$usb" || error 7 "Failed to unmount USB device $label"
fi

### Send notify ================================================================

if [[ "$notify" == 'y' ]]
then
    notify "usb-creator-gtk:$(basename "${iso}") write completed"
fi

### Beep at finish =============================================================

if [[ "$beep" == 'y' ]]
then
    beep -f 2050 -r 2 -d 100 -l 30
fi

