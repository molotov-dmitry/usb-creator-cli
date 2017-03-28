#!/bin/bash

ROOT_PATH="$(cd "$(dirname "$0")" && pwd)"
cd "${ROOT_PATH}" || exit 1

. "${ROOT_PATH}/functions.sh"

sudo echo -n

appinstall 'tools' 'syslinux mtools genisoimage'

iso="$1"
usb="$2"

isodir='/tmp/media/iso'
usbdir='/tmp/media/usb'

while [[ $(file -biL "$usb" | cut -d ';' -f 1) != "inode/blockdevice" ]]
do
    read -e -p "input device path: " usb
done

while ! isoinfo -d -i "${iso/\~/$HOME}" >/dev/null 2>&1
do
    read -e -p "input iso path: " iso
done

iso="${iso/\~/$HOME}"

silentsudo 'make dir for mounting iso' mkdir -p "${isodir}"
silentsudo 'make dir for mounting usb' mkdir -p "${usbdir}"

silentsudo 'unmounting usb' umount -l "${usbdir}"
silentsudo 'unmounting usb' umount -l "$usb"
#silentsudo 'make fs' mkdosfs -n 'LOAD' -I "$usb" -F 32
silentsudo 'mounting usb'   mount "$usb" "${usbdir}" -o rw,uid=$(id -u $USER),gid=$(id -g $USER)
silentsudo 'cleaning usb'   find /media/usb -mindepth 1 -delete

silentsudo 'unmounting iso' umount -l "${isodir}"
silentsudo 'unmounting iso' umount -l "$iso"
silentsudo 'mounting iso'   mount -o loop "$iso" "${isodir}"

silent 'copy files'         cp -LR --preserve=all "${isodir}/". "${usbdir}/"

if [[ -d "${isodir}/EFI/BOOT" && ! -e "${isodir}/EFI/BOOT/bootia32.efi" ]]
then
    silentsudo 'Getting EFI 32 image'       wget https://github.com/jfwells/linux-asus-t100ta/raw/master/boot/bootia32.efi -O "${isodir}/EFI/BOOT/bootia32.efi"
fi

sync

silentsudo 'unmounting usb' umount -l "${usbdir}"
silentsudo 'unmounting usb' umount -l "$usb"
silentsudo 'unmounting iso' umount -l "${isodir}"
silentsudo 'unmounting iso' umount -l "$iso"
