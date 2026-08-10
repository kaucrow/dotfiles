{ config, pkgs, userName, ... }:

let
  dotfiles = "${config.home.homeDirectory}/Documents/dotfiles/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";

  configs = {
    fastfetch = "fastfetch";
    hypr = "hypr";
    kitty = "kitty";
    rofi = "rofi";
    waybar = "waybar";
    swaync = "swaync";
    wlogout = "wlogout";
    matugen = "matugen";
    cava = "cava";
    nvim = "nvim";
    yazi = "yazi";
  };
in
{
  imports = [
    ./desktop.nix
    ./shell.nix
    ./app.nix
  ];

  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = "26.05";

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk3.extraCss = ''@import url("gtk-colors.css");'';
    gtk4.extraCss = ''@import url("gtk-colors.css");'';
  };

  home.file.".local/share/fcitx5/rime/default.custom.yaml".source = link "rime/default.custom.yaml";

  xdg.configFile = builtins.mapAttrs (name: value: {
    source = link value;
  }) configs // {
    "gtk-3.0/gtk-colors.css".source = link "gtk-3.0/gtk-colors.css";
    "gtk-4.0/gtk-colors.css".source = link "gtk-4.0/gtk-colors.css";
  };
}