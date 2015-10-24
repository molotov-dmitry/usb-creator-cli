#!/bin/bash

ROOT_PATH="$(cd "$(dirname "$0")" && pwd)"
cd "${ROOT_PATH}" || exit 1

. "${ROOT_PATH}/functions.sh"

sudo echo -n

appinstall 'tools' 'syslinux mtools genisoimage'

iso="$1"
usb="$2"

while [[ $(file -biL "$usb" | cut -d ';' -f 1) != "inode/blockdevice" ]]
do
    read -e -p "input device path: " usb
done

while ! isoinfo -d -i "${iso/\~/$HOME}" >/dev/null 2>&1
do
    read -e -p "input iso path: " iso
done

iso="${iso/\~/$HOME}"

silentsudo 'make dir for mounting iso' mkdir -p /media/iso
silentsudo 'make dir for mounting usb' mkdir -p /media/usb

silentsudo 'unmounting usb' umount -l /media/usb
silentsudo 'unmounting usb' umount -l "$usb"
#silentsudo 'make fs' mkdosfs -n 'LOAD' -I "$usb" -F 32
silentsudo 'mounting usb' mount "$usb" /media/usb -o rw,uid=$(id -u $USER),gid=$(id -g $USER)
find /media/usb -mindepth 1 -delete

silentsudo 'unmounting iso' umount -l /media/iso
silentsudo 'unmounting iso' umount -l "$iso"
silentsudo 'mounting iso' mount -o loop "$iso" /media/iso

silent 'copy files' cp -LR --preserve=all /media/iso/. /media/usb/

silentsudo 'install syslinux' syslinux "$usb"

silent 'rename isolinux to syslinux' mv /media/usb/isolinux /media/usb/syslinux
silent 'rename isolinux to syslinux' mv /media/usb/syslinux/isolinux.cfg /media/usb/syslinux/syslinux.cfg
silent 'rename isolinux to syslinux' mv /media/usb/syslinux/isolinux.bin /media/usb/syslinux/syslinux.bin

silentsudo 'add try-usb' sed 's/file=\/cdrom/cdrom-detect\/try-usb=true file=\/cdrom/' -i /media/usb/syslinux/*.cfg

silentsudo 'unmounting usb' umount -l /media/usb
silentsudo 'unmounting usb' umount -l "$usb"
silentsudo 'unmounting iso' umount -l /media/iso
silentsudo 'unmounting iso' umount -l "$iso"
