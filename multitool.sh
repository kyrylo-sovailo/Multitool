#!/bin/sh

# Colors
ERROR='\033[0;31m'
SUCCESS='\033[0;32m'
WARNING='\033[0;33m'
DEFAULT='\033[0m'

# Reading arguments
DEVICE=$1
PARTITION=${DEVICE}1
if [ -z "${DEVICE}" ]; then
    printf "${ERROR}Device not specified${DEFAULT}\n"
    exit 1
fi
if [ $(blkid ${DEVICE} | grep PTUUID | wc -l) -ne 1 ]; then
    printf "${ERROR}Device invalid${DEFAULT}\n"
    exit 1
fi
if [ $(blkid ${DEVICE} | grep -o -e 'PTUUID="[a-zA-Z0-9-]*"' | cut -d \" -f 2 | wc -m) -gt 10 ]; then
    printf "${ERROR}Device PTUUID is unusually long${DEFAULT}\n"
    printf "${ERROR}Please verify that you are using the right device and edit the code if absolutely sure${DEFAULT}\n"
    exit 1
fi

LABEL=$2
if [ -z "${LABEL}" ]; then
    printf "${WARNING}Label not specified, using default MULTITOOL${DEFAULT}\n"
    LABEL=MULTITOOL
fi

# Unmount partition
umount ${PARTITION}

# Create partitions
cat << EOF > multitool.temp
o
n
p



y
t
0b
w
EOF
fdisk ${DEVICE} < multitool.temp 2>/dev/null
if [ $? -ne 0 ]; then
    printf "${ERROR}fdisk failed${DEFAULT}\n"
    rm multitool.temp
    exit 1
else
    rm multitool.temp
fi
sleep 1

# Format partition
mkfs.fat ${PARTITION} -F 32 -n ${LABEL}
if [ $? -ne 0 ]; then
    printf "${ERROR}mkfs.fat failed${DEFAULT}\n"
    exit 1
fi
UUID=$(blkid ${PARTITION} | grep -o -e ' UUID="[a-zA-Z0-9-]*"' | cut -d \" -f 2)
if [ -z "${UUID}" ]; then
    printf "${ERROR}mkdir failed${DEFAULT}\n"
    exit 1
fi

# Mount
if [ ! -d multitool ]; then
    mkdir multitool
    if [ $? -ne 0 ]; then
        printf "${ERROR}mkdir failed${DEFAULT}\n"
        exit 1
    fi
fi
mount ${PARTITION} multitool
if [ $? -ne 0 ]; then
    printf "${ERROR}mount failed${DEFAULT}\n"
    exit 1
fi

# Install grub
grub-install ${DEVICE} --target=i386-pc --root-directory=multitool --boot-directory=multitool --efi-directory=multitool --removable
if [ $? -ne 0 ]; then
    printf "${WARNING}grub-install --target=i386-pc failed${DEFAULT}\n"
fi
grub-install ${PARTITION} --root-directory=multitool --boot-directory=multitool --efi-directory=multitool --removable
if [ $? -ne 0 ]; then
    printf "${ERROR}grub-install failed${DEFAULT}\n"
    exit 1
fi

# Configure grub
if [ ! -d multitool/grub/multitool ]; then
    mkdir -p multitool/grub/multitool
    if [ $? -ne 0 ]; then
        printf "${ERROR}mkdir failed${DEFAULT}\n"
        exit 1
    fi
fi
cp multitool.png multitool/grub/multitool/multitool.png
cat << EOF > multitool/grub/grub.cfg
# This configuration was generated as part of github.com/kyrylo-sovailo/Multitool project
# Developed by Kyrylo Sovailo

search --fs-uuid ${UUID} --set
insmod all_video
insmod part_gpt
insmod loopback
insmod png
terminal_output gfxterm
loadfont unicode
background_image /grub/multitool/multitool.png

set default=0
set timeout=10
set gfxpayload=text

menuentry "TinyCore" {
    terminal_output console
    set iso="/grub/multitool/Core-current.iso"
    loopback loop \${iso}
    linux (loop)/boot/vmlinuz ro
    initrd (loop)/boot/core.gz
}
menuentry "Debian" {
    # Wiki: wiki.debian.org/DebianLive/MultibootISO
    terminal_output console
    set iso="/grub/multitool/debian-live-12.0.0-amd64-standard.iso"
    set kernel=6.1.0-9
    loopback loop \${iso}
    linux (loop)/live/vmlinuz-\${kernel}-amd64 findiso=\${iso} boot=live ro
    initrd (loop)/live/initrd.img-\${kernel}-amd64
}
menuentry "OpenSUSE" {
    # Info: jeevanism.wordpress.com/2020/05/13/boot-opensuse-live-iso-from-hdd-using-grub2/
    terminal_output console
    set iso="/grub/multitool/openSUSE-Leap-15.5-XFCE-Live-x86_64-Build10.57-Media.iso"
    set label=openSUSE_Leap_15.5_XFCE_Live
    loopback loop \${iso}
    linux (loop)/boot/x86_64/loader/linux boot=isolinux iso-scan/filename=\${iso} root=live:CDLABEL=\${label} rd.live.image ro
    initrd (loop)/boot/x86_64/loader/initrd
}
menuentry "Arch" {
    # Wiki: wiki.archlinux.org/title/Multiboot_USB_drive#Boot_entries
    terminal_output console
    set iso="/grub/multitool/archlinux-x86_64.iso"
    loopback loop \${iso}
    linux (loop)/arch/boot/x86_64/vmlinuz-linux img_dev=/dev/disk/by-uuid/${UUID} img_loop=\${iso} earlymodules=loop ro
    initrd (loop)/arch/boot/intel-ucode.img (loop)/arch/boot/amd-ucode.img (loop)/arch/boot/x86_64/initramfs-linux.img
}
menuentry "Gentoo" {
    # Wiki: wiki.gentoo.org/wiki/GRUB/Chainloading#ISO_images
    terminal_output console
    set iso="/grub/multitool/install-amd64-minimal-20230611T170207Z.iso"
    loopback loop \${iso}
    linux (loop)/boot/gentoo isoboot=\${iso} root=/dev/ram0 init=/linuxrc looptype=squashfs loop=/image.squashfs cdroot ro
    initrd (loop)/boot/gentoo.igz
}
#menuentry "FreeDOS" {
#    terminal_output console
#    set iso="/grub/multitool/FD13LIVE.iso"
#    loopback loop \${iso}
#    linux (loop)/isolinux/memdisk
#    initrd (loop)/isolinux/fdlive.img
#}
EOF

# Unmount
umount ${PARTITION}
if [ $? -ne 0 ]; then
    printf "${WARNING}umount failed${DEFAULT}\n"
else
    rm -r multitool
    if [ $? -ne 0 ]; then
        printf "${WARNING}rm failed${DEFAULT}\n"
    fi
fi

# Success
printf "${SUCCESS}Success${DEFAULT}\n"