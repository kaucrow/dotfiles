{
  description = "NixOS with Hyprland";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }:
  let
    host = import ./nixos/host.nix;
    system = "x86_64-linux";
    mkSystem = modules: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = host;
      modules = [
        ./nixos/configuration.nix
        disko.nixosModules.disko
      ] ++ modules;
    };
    homeManagerModules = [
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${host.userName} = import ./home;
          backupFileExtension = "backup";
          extraSpecialArgs = host;
        };
      }
    ];
  in
  {
    nixosConfigurations.${host.hostName} = mkSystem homeManagerModules;
    nixosConfigurations."${host.hostName}-install" = mkSystem [ ];
  };
}