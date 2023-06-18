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
grub-install ${DEVICE} --target=i386-pc --root-directory=multitool --boot-directory=multitool --removable
if [ $? -ne 0 ]; then
	printf "${WARNING}grub-install --target=i386-pc failed${DEFAULT}\n"
fi
grub-install ${PARTITION} --root-directory=multitool --efi-directory=multitool --boot-directory=multitool --removable
if [ $? -ne 0 ]; then
	printf "${ERROR}grub-install failed${DEFAULT}\n"
	exit 1
fi

# Configure grub

printf "${SUCCESS}Success${DEFAULT}\n"