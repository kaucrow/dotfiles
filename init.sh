#!/bin/sh

set -e

USER_NAME=""
USER_EMAIL=""
HOST_NAME=""
DISK=""
CPU=""
GPU=""
INSTALL_TYPE=""
USER_HOME=""
USER_DOCS=""
USER_PICTURES=""
DOTFILES_TARGET=""
STATE_DIR="/mnt/var/lib/nix-dotfiles-install-state"
RESET_STATE=0

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != "--reset" ]; }; then
  echo "Usage: $0 [--reset]"
  exit 1
fi

if [ "${1:-}" = "--reset" ]; then
  RESET_STATE=1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "please run in root (sudo $0)"
  exit 1
fi

step_done() {
  [ -f "${STATE_DIR}/$1.done" ]
}

mark_done() {
  mkdir -p "${STATE_DIR}"
  touch "${STATE_DIR}/$1.done"
}

run_once() {
  step="$1"
  desc="$2"
  shift 2

  if step_done "${step}"; then
    echo "==> ${desc}: skipped"
    return 0
  fi

  echo "==> ${desc}"
  "$@"
  mark_done "${step}"
}

run_always() {
  desc="$1"
  shift

  echo "==> ${desc}"
  "$@"
}

read_host_config() {
  USER_NAME="$(sed -n 's/.*userName = "\(.*\)";.*/\1/p' nixos/host.nix)"
  USER_EMAIL="$(sed -n 's/.*userEmail = "\(.*\)";.*/\1/p' nixos/host.nix)"
  HOST_NAME="$(sed -n 's/.*hostName = "\(.*\)";.*/\1/p' nixos/host.nix)"
  DISK="$(sed -n 's/.*disk = "\(.*\)";.*/\1/p' nixos/host.nix)"
  CPU="$(sed -n 's/.*cpu = "\(.*\)";.*/\1/p' nixos/host.nix)"
  GPU="$(sed -n 's/.*gpu = "\(.*\)";.*/\1/p' nixos/host.nix)"
}

set_user_paths() {
  USER_HOME="/mnt/home/${USER_NAME}"
  USER_DOCS="${USER_HOME}/Documents"
  USER_PICTURES="${USER_HOME}/Pictures"
  DOTFILES_TARGET="${USER_DOCS}/dotfiles"
}

prompt_value() {
  label="$1"
  current="$2"
  options="${3:-}"

  if [ -n "${options}" ]; then
    printf '%s (%s) [%s]: ' "${label}" "${options}" "${current}" >&2
  else
    printf '%s [%s]: ' "${label}" "${current}" >&2
  fi

  read -r value
  if [ -n "${value}" ]; then
    printf '%s' "${value}"
  else
    printf '%s' "${current}"
  fi
}

validate_user_name() {
  case "$1" in
    "" | *[!a-z0-9_-]* | [!a-z_]*)
      echo "invalid userName: $1"
      echo "use lowercase letters, digits, '_' or '-', and start with a letter or '_'."
      exit 1
      ;;
  esac
}

validate_host_name() {
  case "$1" in
    "" | *[!A-Za-z0-9-]* | -* | *-)
      echo "invalid hostName: $1"
      echo "use letters, digits or '-', and do not start/end with '-'."
      exit 1
      ;;
  esac
}

validate_choice() {
  value="$1"
  choices="$2"
  label="$3"

  for choice in ${choices}; do
    if [ "${value}" = "${choice}" ]; then
      return 0
    fi
  done

  echo "invalid ${label}: ${value}"
  echo "valid values: ${choices}"
  exit 1
}

validate_install_type() {
  validate_choice "${INSTALL_TYPE}" "full-disk dual-boot" "install type"
}

ask_host_config() {
  echo "==> Configure host"
  USER_NAME="$(prompt_value "User name" "${USER_NAME}")"
  USER_EMAIL="$(prompt_value "User email" "${USER_EMAIL}")"
  HOST_NAME="$(prompt_value "Host name" "${HOST_NAME}")"
  DISK="$(prompt_value "Target disk" "${DISK}")"
  CPU="$(prompt_value "CPU" "${CPU}" "amd/intel")"
  GPU="$(prompt_value "GPU" "${GPU}" "nvidia/amd/intel/blank=integrated")"

  if [ -z "${GPU}" ]; then
    GPU="${CPU}"
  fi

  INSTALL_TYPE="$(prompt_value "Install type" "${INSTALL_TYPE}" "full-disk/dual-boot")"

  validate_user_name "${USER_NAME}"
  validate_host_name "${HOST_NAME}"
  validate_choice "${CPU}" "amd intel" "cpu"
  validate_choice "${GPU}" "nvidia amd intel" "gpu"
  validate_install_type
}

write_host_config() {
  cat > nixos/host.nix <<EOF
{
  userName = "${USER_NAME}";
  userEmail = "${USER_EMAIL}";
  hostName = "${HOST_NAME}";
  disk = "${DISK}";
  cpu = "${CPU}";
  gpu = "${GPU}";
}
EOF
}

validate_config() {
  if [ -z "${USER_NAME}" ] || [ -z "${USER_EMAIL}" ] || [ -z "${HOST_NAME}" ] || [ -z "${DISK}" ] || [ -z "${CPU}" ] || [ -z "${GPU}" ]; then
    echo "failed to read userName, userEmail, hostName, disk, cpu, or gpu from nixos/host.nix"
    exit 1
  fi

  if [ ! -b "${DISK}" ]; then
    echo "target disk does not exist or is not a block device: ${DISK}"
    echo
    lsblk
    exit 1
  fi
}

confirm_disko() {
  echo "==> Install summary"
  echo "    User: ${USER_NAME}"
  echo "    Mail: ${USER_EMAIL}"
  echo "    Host: ${HOST_NAME}"
  echo "    Disk: ${DISK}"
  echo "    CPU : ${CPU}"
  echo "    GPU : ${GPU}"
  echo
  echo "==> Current block devices"
  lsblk
  echo
  echo "WARNING: this will repartition and format ${DISK}."
  echo "All data on ${DISK} will be erased."
  printf 'Type exactly "ERASE %s" to continue: ' "${DISK}"
  read -r CONFIRM
  if [ "${CONFIRM}" != "ERASE ${DISK}" ]; then
    echo "confirmation mismatch, aborting."
    exit 1
  fi
}

confirm_disko_dualboot() {
  echo "==> Install summary"
  echo "    User: ${USER_NAME}"
  echo "    Mail: ${USER_EMAIL}"
  echo "    Host: ${HOST_NAME}"
  echo "    Disk: ${DISK}"
  echo "    CPU : ${CPU}"
  echo "    GPU : ${GPU}"
  echo "    Type: dual-boot"
  echo
  echo "==> Current block devices"
  lsblk
  echo
  echo "This will create NixOS partitions in FREE SPACE on ${DISK}."
  echo "Existing Windows partitions will NOT be modified."
  echo "A new 1G EFI, 8G swap, and BTRFS root will be created."
  printf 'Type exactly "USE FREE SPACE %s" to continue: ' "${DISK}"
  read -r CONFIRM
  if [ "${CONFIRM}" != "USE FREE SPACE ${DISK}" ]; then
    echo "confirmation mismatch, aborting."
    exit 1
  fi
}

copy_windows_efi() {
  echo "==> Copying Windows EFI files to NixOS ESP..."

  WINDOWS_ESP=$(blkid | grep "EFI system partition" | grep -v NIXOS | cut -d: -f1 | head -1)

  if [ -z "${WINDOWS_ESP}" ]; then
    echo "Warning: could not find Windows EFI partition."
    echo "Systemd-boot may not detect Windows automatically."
    echo "You can copy the files manually later."
    return 0
  fi

  echo "    Found Windows ESP: ${WINDOWS_ESP}"
  mkdir -p /mnt/windows-esp
  mount "${WINDOWS_ESP}" /mnt/windows-esp

  if [ -d "/mnt/windows-esp/EFI/Microsoft" ]; then
    mkdir -p /mnt/boot/EFI
    cp -r /mnt/windows-esp/EFI/Microsoft /mnt/boot/EFI/
    echo "    Copied EFI/Microsoft to /boot/EFI/"
  else
    echo "    Warning: EFI/Microsoft not found on Windows ESP."
  fi

  umount /mnt/windows-esp
  rmdir /mnt/windows-esp
  echo "    Done."
}

run_disko() {
  desc="1. Running Disko for partitioning and mounting..."

  if [ "${RESET_STATE}" -eq 0 ] && step_done "01-disko"; then
    echo "==> ${desc}: skipped"
    return 0
  fi

  if [ "${INSTALL_TYPE}" = "dual-boot" ]; then
    confirm_disko_dualboot
    echo "==> Creating partitions in free space..."
    sh ./nixos/partition-dualboot.sh "${DISK}"
    echo "==> ${desc}"
    nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode format,mount ./nixos/disko-dualboot.nix
    copy_windows_efi
  else
    confirm_disko
    echo "==> ${desc}"
    nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./nixos/disko.nix
  fi

  mark_done "01-disko"
}

generate_hardware_config() {
  nixos-generate-config --root /mnt
}

copy_config() {
  cp /mnt/etc/nixos/hardware-configuration.nix ./nixos/
  cp -r flake.* ./nixos/ ./home/ ./dotfiles/ /mnt/etc/nixos/
}

install_nixos() {
  nixos-install --flake "/mnt/etc/nixos#${HOST_NAME}-install"
}

set_user_password() {
  nixos-enter --root /mnt -c "passwd ${USER_NAME}"
}

prepare_user_files() {
  mkdir -p "${USER_DOCS}" "${USER_PICTURES}"
  rm -rf "${DOTFILES_TARGET}"
  cp -a . "${DOTFILES_TARGET}"

  # Ensure all scripts are executable
  find "${DOTFILES_TARGET}" -name "*.sh" -exec chmod +x {} \;

  if [ -d "${DOTFILES_TARGET}/wallpapers" ]; then
    mv "${DOTFILES_TARGET}/wallpapers" "${USER_PICTURES}/wallpapers"
  fi

  nixos-enter --root /mnt -c "chown -R ${USER_NAME}:users /home/${USER_NAME}/Documents /home/${USER_NAME}/Pictures"
}

activate_full_system() {
  nixos-enter --root /mnt -c "nixos-rebuild boot --flake /home/${USER_NAME}/Documents/dotfiles#${HOST_NAME}"
}

read_host_config
ask_host_config
write_host_config
set_user_paths
validate_config
run_disko
run_once "02-hardware" "2. Generating hardware configuration..." generate_hardware_config
run_always "3. Preparing configuration files..." copy_config
run_once "04-nixos-install" "4. Installing base NixOS..." install_nixos
run_once "05-user-files" "5. Preparing user files..." prepare_user_files
run_once "06-full-system" "6. Activating full system configuration..." activate_full_system
run_always "7. Setting user password..." set_user_password
echo "==> Installation complete! Please remove the installation media and reboot."
