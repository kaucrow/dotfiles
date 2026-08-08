# Dual-boot disko config.
# Format & mount only (no partition table management).
# Requires partitions to already exist with partlabels:
#   NIXOS-EFI  (1G, vfat)
#   NIXOS-SWAP (8G, swap)
#   NIXOS-ROOT (rest, btrfs)
#
# Run with: disko --mode format,mount ./nixos/disko-dualboot.nix

{
  disko.devices = {
    disk = {
      efi = {
        device = "/dev/disk/by-partlabel/NIXOS-EFI";
        type = "disk";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };
      swap = {
        device = "/dev/disk/by-partlabel/NIXOS-SWAP";
        type = "disk";
        content = {
          type = "swap";
          resumeDevice = true;
        };
      };
      root = {
        device = "/dev/disk/by-partlabel/NIXOS-ROOT";
        type = "disk";
        content = {
          type = "btrfs";
          extraArgs = [ "-f" ];
          subvolumes = {
            "/root" = {
              mountpoint = "/";
              mountOptions = [ "compress=zstd" "noatime" ];
            };
            "/home" = {
              mountpoint = "/home";
              mountOptions = [ "compress=zstd" "noatime" ];
            };
            "/nix" = {
              mountpoint = "/nix";
              mountOptions = [ "compress=zstd" "noatime" ];
            };
          };
        };
      };
    };
  };
}