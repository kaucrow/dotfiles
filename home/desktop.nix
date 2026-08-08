{ pkgs, ... }:

{
  home.packages = with pkgs; [
    quickshell
    waybar
    rofi
    awww
    imv
    mpv
    mpvpaper
    wf-recorder
    grim
    slurp
    cliphist
    wl-clipboard
    wl-clip-persist
    wlogout
    hyprlock
    hypridle
    hyprpolkitagent
    swaynotificationcenter
    libnotify
    bibata-cursors
    pwvucontrol
    networkmanagerapplet
    udiskie
  ];

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=18";
        pad = "10x10 center";
      };
      colors-dark = {
        alpha = 0.8;
      };
    };
  };
}