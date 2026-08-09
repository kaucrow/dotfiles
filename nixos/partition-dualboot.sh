#!/bin/sh
# Create NixOS partitions in the largest free space on a disk.
# Creates: 1G EFI (NIXOS-EFI), 8G swap (NIXOS-SWAP), remaining btrfs (NIXOS-ROOT).
# Existing partitions (Windows etc.) are NOT touched.
#
# Usage: ./nixos/partition-dualboot.sh /dev/sdX

set -e

DISK="$1"

if [ -z "${DISK}" ]; then
  echo "Usage: $0 /dev/sdX"
  exit 1
fi

if [ ! -b "${DISK}" ]; then
  echo "Error: ${DISK} is not a valid block device."
  exit 1
fi

# Check sgdisk is available
if ! command -v sgdisk >/dev/null 2>&1; then
  echo "sgdisk not found. Installing gptfdisk via nix..."
  nix-env -iA nixos.gptfdisk 2>/dev/null || {
    echo "Trying nix-shell..."
    nix-shell -p gptfdisk --run "sgdisk --version" || {
      echo "Error: could not install gptfdisk. Please install it manually."
      exit 1
    }
  }
fi

echo "==> Current partition layout on ${DISK}:"
sgdisk -p "${DISK}"
echo

# Find free sectors
FREE_INFO=$(sgdisk -p "${DISK}" | grep "Total free space")
echo "==> ${FREE_INFO}"

# Parse free space: e.g., "Total free space is 123456789 sectors (58.9 GiB)"
FREE_SECTORS=$(echo "${FREE_INFO}" | grep -oP '\d+(?= sectors)')
if [ -z "${FREE_SECTORS}" ] || [ "${FREE_SECTORS}" -eq 0 ]; then
  echo "Error: no free space found on ${DISK}."
  echo "Shrink your Windows partition first (from within Windows)."
  exit 1
fi

# 1G + 8G + 20G minimum = 29G. Sectors are typically 512 bytes.
# 29 GiB * 1024 * 1024 * 1024 / 512 = 29 * 2097152 = ~60,817,408 sectors
MIN_SECTORS=$((29 * 1024 * 1024 * 1024 / 512))
if [ "${FREE_SECTORS}" -lt "${MIN_SECTORS}" ]; then
  echo "Error: not enough free space (need at least 29 GiB)."
  exit 1
fi

echo
echo "==> Creating partitions in largest free space..."
echo "    Partition 1: 1 GiB EFI  (partlabel: NIXOS-EFI)"
echo "    Partition 2: 8 GiB SWAP (partlabel: NIXOS-SWAP)"
echo "    Partition 3: rest BTRFS (partlabel: NIXOS-ROOT)"
echo

# sgdisk -n 0:0:... uses the largest available free space at that moment.
# -n <partnum>:<start>:<size>  0 means "lowest available / start of free space"
# -t <partnum>:<type>         EF00=EFI, 8200=swap, 8300=Linux filesystem
# -c <partnum>:<label>        GPT partition name/label
sgdisk \
  -n 0:0:+1G -t 0:EF00 -c 0:NIXOS-EFI \
  -n 0:0:+8G -t 0:8200 -c 0:NIXOS-SWAP \
  -n 0:0:0   -t 0:8300 -c 0:NIXOS-ROOT \
  "${DISK}"

echo
echo "==> Waiting for kernel to detect new partitions..."
udevadm settle
partprobe "${DISK}" 2>/dev/null || true
sleep 2

echo
echo "==> Partitions created. New layout:"
sgdisk -p "${DISK}"
echo
echo "==> Partitioning complete."