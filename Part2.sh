#/bin/bash
#!~ 2021.12.11

	# swap
	clear; read -p "Select the swapfile size in megabytes (1024): " swapsize
	dd if=/dev/zero of=/swapfile bs=1MB count=$swapsize status=progress
	chmod 600 /swapfile; mkswap /swapfile; swapon /swapfile
	echo "" >> /etc/fstab
	echo "/swapfile none swap defaults 0 0" >> /etc/fstab

	# users
	clear; read -p "Type your new username (user): " username
	useradd -mG wheel $username; printf "- Root passwd -"; echo ""; passwd root; clear; printf "- $username passwd -"; echo ""; passwd $username
	sed -i -e "s/# %wheel ALL=(ALL) ALL/ %wheel ALL=(ALL) ALL/I" /etc/sudoers

	# locale
	clear; read -p "Type your locale (en_US.UTF-8 UTF-8): " locale; echo $locale >> /etc/locale.gen; locale-gen; hwclock --systohc
	clear; read -p "Type the nearest city/timezone (Denver): " city; zone=$(find /usr/share/zoneinfo/America/ -type f -name *$city*)
	ln -sf /usr/share/zoneinfo/$zone /etc/localtime

	# hostname
	clear; read -p "Type your new hostname (arch): " hostname
	echo $hostname >> /etc/hostname
	echo "127.0.0.1	localhost" >> /etc/hosts
	echo "::1	localhost" >> /etc/hosts
	echo "127.0.1.1	$hostname.localdomain	$hostname" >> /etc/hosts

	# pacman
	clear; printf "Optimizing pacman\n\n"
	sed -i -e "s/#VerbosePkgLists/VerbosePkgLists/I" /etc/pacman.conf
	sed -i -e "s/#ParallelDownloads = 5/ParallelDownloads = 5/I" /etc/pacman.conf
	pacman -Syy --noconfirm
	reflector -c 'Netherlands' --fastest 10 -a 6 --protocol https --ipv4 --sort rate --download-timeout 10 --save /etc/pacman.d/mirrorlist --verbose

	# firmware
	clear; read -p "Select your video driver controller (intel, amd or nouveau): " vdriver
	pacman -S --needed grub efibootmgr os-prober networkmanager network-manager-applet pipewire pipewire-alsa pipewire-pulse wireplumber alsa-utils\
	xf86-video-$vdriver xorg-server

	# grub
	clear; printf "Installing GRUB\n\n"
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
	grub-mkconfig -o /boot/grub/grub.cfg

	# DE
	clear; printf "\n\n gnome\n budgie\n xserver\n\n"; read -p "Select a desktop environment: " desktop
	p="pacman -S --noconfirm --needed"; case $desktop in gnome) $p gnome-shell;; budgie) $p budgie-desktop;; xserver) $p xterm xorg-xinit;; esac

	# utils
	pacman -S --needed --noconfirm tilix bleachbit nautilus gedit gparted gnome-system-monitor eog evince baobab lightdm \
	lightdm-gtk-greeter dconf-editor file-roller gnome-calculator gnome-screenshot neofetch networkmanager-openvpn rhythmbox vlc xdg-user-dirs xdg-utils \
	dosfstools mtools rsync #firefox libreoffice-fresh

	# services
	systemctl enable lightdm.service
	systemctl enable NetworkManager

	# copy configs
	cp -f config/pacman.info /etc/pacman.conf
	cp -f config/mkinitcpio.info /etc/mkinitcpio.conf && mkinitcpio -P
	cp -f config/iptables.info /etc/iptables/iptables.rules && iptables-restore /etc/iptables/iptables.rules
	cp -f config/grub.info /etc/default/grub
	mkdir -p /etc/systemd/sleep.conf.d/ && cp -f config/no-hibernate.info /etc/systemd/sleep.conf.d/no-hibernate-suspend.conf
	mkdir -p /etc/systemd/logind.conf.d/ && cp -f config/no-sleep.info /etc/systemd/logind.conf.d/no-hibernate-suspend.conf
	exit
