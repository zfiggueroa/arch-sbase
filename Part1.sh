#/bin/bash
#!~ 2021.12.11
PS3=":"

# arrays
declare	-a drives
declare -a kernel
drives='/dev/'$(lsblk -I 8 -d | grep -v 0B | awk '{ print $1}' | grep -v NAME)
kernel="linux linux-lts linux-hardened linux-zen"

select_drive () {
	# select drive
	clear; printf "Drives found on this system:\n"'%s\n' "${drives[@]}"; printf "\n"
	read -p "Select installation drive: " target; confirm_drive $target
}

confirm_drive () {
	# check lsblk
	if [[ ! " ${drives[*]} " =~ " ${target} " ]]; then clear; printf "\n\033[31m"" Drive '$target' not found on lsblk\n\n""\033[37m"; fi

	# confirm drive
	read -p "Continue install on '$1' (y/n)?: " confirm
	if [[ $confirm == [yY] ]]; then	partition $1; else select_drive; fi
}

partition () {
	# partitions sizes
	clear; printf "\n Select partitions size, use '+' before size and 'M' or 'G' after\n\n"
	read -p " partition size for 'boot' (+200M): " bsize
	read -p " partition size for 'root' (+10G): " rsize
	printf "\n"; read -p " Commit changes on '$1' (y/n)?: " confirm
	if [[ $confirm != [yY] ]]; then partition $1; fi

	# squish! sgdisk!
	sgdisk --zap-all $1 > /dev/null 2>&1
	sgdisk --clear $1 > /dev/null 2>&1
	sgdisk --new=1::$bsize --typecode=1:EF00 $1 > /dev/null 2>&1
	sgdisk --new=2::$rsize --typecode=2:8300 $1 > /dev/null 2>&1
	sgdisk --new=3::0 --typecode=3:8300 $1 > /dev/null 2>&1

	# mkfs
	mkfs.vfat -F -F "$11" > /dev/null 2>&1
	mkfs.ext4 -F -F "$12" > /dev/null 2>&1
	mkfs.ext4 -F -F "$13" > /dev/null 2>&1

	# mount points
	mount "$12" /mnt
	mkdir -p /mnt/{boot,home}
	mount "$11" /mnt/boot
	mount "$13" /mnt/home
}; select_drive

select_kernel(){
	# choose kernel
	clear; printf "Kernels avialables:\n"'%s\n' "${kernel[@]}"; printf "\n"
	read -p "Select kernel to install: " linux

	# confirm kernel
	if [[ ! " ${kernel[*]} " =~ " ${linux} " ]]; then clear; printf "\n\033[31m"" Kernel '$linux' not found\n\n""\033[37m"; fi
	printf "\n"; read -p "Install this kernel '$linux' (y/n)?: " confirm
	if [[ $confirm == [yY] ]]; then printf "\n$linux selected\n"; else select_kernel; fi
}; select_kernel

	# pac-s-trap
	clear; printf "\nInstalling base system packages\n\n"
	cp -f config/pacman.info /etc/pacman.conf
	pacstrap /mnt base base-devel $linux $linux-headers linux-firmware git reflector vim

	# chroot
	genfstab -U /mnt /mnt/etc/fstab; clear
	cp -R . /mnt/arch-sbase/
	arch-chroot /mnt sh /arch-sbase/Part2.sh
	rm -r /mnt/arch-sbase/

clear; printf "Installation complete, now you can reboot \(• ◡ •)/"
