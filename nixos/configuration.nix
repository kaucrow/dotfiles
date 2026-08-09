{ config, lib, pkgs, userName, hostName, cpu, gpu, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = hostName;
    networkmanager.enable = true;
  };

  time.timeZone = "America/Caracas";

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      inter
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      dejavu_fonts
      font-awesome
      corefonts
    ];
    fontconfig = {
      enable = true;
      cache32Bit = true;
      defaultFonts = {
        sansSerif = [ "Inter" "Noto Sans CJK SC" "Noto Sans CJK TC" ];
        serif = [ "Noto Serif" "Noto Serif CJK SC" "Noto Serif CJK TC" ];
        monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono CJK SC" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General.Experimental = true;
    };
  };

  services.udisks2.enable = true;

  services.power-profiles-daemon.enable = true;

  # CPU/GPU
  services.xserver.videoDrivers =
    if gpu == "nvidia" then [ "nvidia" ]
    else if gpu == "amd" then [ "amdgpu" ]
    else if gpu == "intel" then [ "modesetting" ]
    else [ ];

  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = lib.optionals (gpu == "nvidia") [ pkgs.nvidia-vaapi-driver ];
    };
    cpu.amd.updateMicrocode = cpu == "amd";
    cpu.intel.updateMicrocode = cpu == "intel";
    nvidia = lib.mkIf (gpu == "nvidia") {
      modesetting.enable = true;
      open = true; # RTX 50/Blackwell
      nvidiaSettings = true;
      nvidiaPersistenced = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      powerManagement.enable = true;
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  programs.zsh.enable = true;
  services.getty.autologinUser = userName;
  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "render" ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;
  environment = {
    systemPackages = with pkgs; [
      vim
      git
      wget
      papirus-icon-theme
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
      # WLR_NO_HARDWARE_CURSORS = "1";
      # ELECTRON_OZONE_PLATFORM_HINT = "auto";
    } // lib.optionalAttrs (gpu == "nvidia") {
      NVD_BACKEND = "direct";
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}