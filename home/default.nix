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
  home.stateVersion = "25.05";

  home.file.".local/share/fcitx5/rime/default.custom.yaml".source = link "rime/default.custom.yaml";

  xdg.configFile = builtins.mapAttrs (name: value: {
    source = link value;
  }) configs;
}