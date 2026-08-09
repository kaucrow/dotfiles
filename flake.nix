{
  description = "Kaucrow's NixOS";

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
    specialArgs = host;

    mkSystem = modules: nixpkgs.lib.nixosSystem {
      inherit system;
      inherit specialArgs;
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
          extraSpecialArgs = specialArgs;
        };
      }
    ];
  in
  {
    nixosConfigurations.${host.hostName} = mkSystem homeManagerModules;
    nixosConfigurations."${host.hostName}-install" = mkSystem [ ];
  };
}