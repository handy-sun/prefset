#!/usr/bin/env bash
## 02-partition.sh — GPT partition + format (ESP + btrfs)
## Usage: ./02-partition.sh [DISK]
## Default: /dev/sda
set -euo pipefail

DISK="${1:-/dev/sda}"

if [[ ! -b "${DISK}" ]]; then
    echo "Error: ${DISK} is not a block device"
    exit 1
fi

echo "========================================="
echo "  About to partition ${DISK}"
echo "  !! All data will be erased !!"
echo "========================================="
read -rp "Confirm? (y/N): " confirm
[[ "${confirm}" == [yY] ]] || exit 0

echo ">>> Creating GPT partition table..."
parted "${DISK}" -- mklabel gpt

echo ">>> Creating EFI system partition (1GiB)..."
parted "${DISK}" -- mkpart ESP fat32 1MiB 1024MiB
parted "${DISK}" -- set 1 esp on

echo ">>> Creating primary partition (remaining space)..."
parted "${DISK}" -- mkpart primary 1024MiB 100%

echo ">>> Formatting EFI partition..."
mkfs.fat -F32 "${DISK}1"

echo ">>> Formatting btrfs partition..."
mkfs.btrfs -L nixos "${DISK}2"

echo ""
echo ">>> Partitioning done:"
lsblk "${DISK}"
echo ""
echo "Next: run 03-subvolumes.sh"
