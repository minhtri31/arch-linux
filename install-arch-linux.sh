#!/bin/bash

set -e

error() {
  echo -e "\033[1;31mERROR:\033[0m $1" >&2
  exit 1
}

# Variables
DISK="${1:-/dev/sda}"
HOSTNAME="${HOSTNAME:-lucifer}"
USERNAME="${USERNAME:-yllin}"
TIMEZONE="${TIMEZONE:-Asia/Ho_Chi_Minh}"

# 1. Check for root
[ "$EUID" -ne 0 ] && error "Script must be run as root."

# 2. Confirm UEFI mode
[ -d /sys/firmware/efi ] || error "System is not booted in UEFI mode."

# 3. Check disk size
DISK_SIZE=$(blockdev --getsize64 "$DISK")
MIN_SIZE=$((40*1024*1024*1024)) # 40GB
[ "$DISK_SIZE" -lt "$MIN_SIZE" ] && error "Disk $DISK is too small (minimum 40GB required)."

# 4. Confirm user intention
while [[ ! "$confirm" =~ ^[YyNn]$ ]]; do
  read -rp $'\n\033[1;33mThis script will ERASE the entire disk '"$DISK"' and install Arch Linux minimal. Continue? (y/N): \033[0m' confirm
  confirm=${confirm:-N}
done
[[ "$confirm" =~ ^[Yy]$ ]] || error "Installation aborted."

# 5. Partition disk
echo -e "\n\033[1;34mPartitioning $DISK...\033[0m"
parted "$DISK" --script mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 esp on \
  mkpart primary linux-swap 513MiB 8705MiB \
  mkpart primary ext4 8705MiB 38913MiB \
  mkpart primary ext4 38913MiB 100% || error "Failed to partition $DISK."

# 6. Format partitions
mkfs.fat -F32 "${DISK}1" || error "Failed to format EFI partition."
mkswap "${DISK}2" || error "Failed to format swap partition."
mkfs.ext4 -F "${DISK}3" || error "Failed to format root partition."
mkfs.ext4 -F "${DISK}4" || error "Failed to format home partition."

# 7. Mount partitions
mount "${DISK}3" /mnt || error "Failed to mount root partition."
mkdir -p /mnt/boot /mnt/home
mount "${DISK}1" /mnt/boot || error "Failed to mount EFI partition."
mount "${DISK}4" /mnt/home || error "Failed to mount home partition."
swapon "${DISK}2" || error "Failed to activate swap."

# 8. Check internet
ping -c 1 archlinux.org &>/dev/null || error "No internet connection."

# 9. Install base system
pacstrap /mnt base linux linux-firmware nano sudo networkmanager grub efibootmgr || error "Failed to install base system."

# 10. Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
[ -s /mnt/etc/fstab ] || error "Failed to generate fstab."

# 11. Chroot and configure
arch-chroot /mnt /bin/bash <<EOF
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen || exit 1
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname
cat <<EOL > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOL

# Enable NetworkManager
systemctl enable NetworkManager

# Set root password
echo "Set root password:"
passwd root || exit 1

# Add user and set password
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "Set password for user $USERNAME:"
passwd "$USERNAME" || exit 1

# Allow sudo for wheel group
echo '%wheel ALL=(ALL:ALL) ALL' > /tmp/sudoers.tmp
visudo -c -f /tmp/sudoers.tmp && cat /tmp/sudoers.tmp >> /etc/sudoers

# Install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB || exit 1
grub-mkconfig -o /boot/grub/grub.cfg || exit 1
EOF

# 12. Cleanup and done
umount -R /mnt
swapoff "${DISK}2"
echo -e "\n\033[1;32mInstallation complete. Please remove the installation media and reboot.\033[0m"
