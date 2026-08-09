{ pkgs, rose-pine-cursor, ... }:

{
  home.packages = with pkgs; [
    quickshell
    kitty
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
    (pkgs.runCommand "rose-pine-cursor" { } ''
      mkdir -p $out/share/icons
      for d in ${rose-pine-cursor}/*/; do
        [ -f "$d/index.theme" ] || [ -f "$d/cursor.theme" ] && cp -r "$d" $out/share/icons/
      done
    '')
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