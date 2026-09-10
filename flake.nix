{
  description = "base";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.blackwell = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          inputs.determinate.nixosModules.default
          ./hardware-configuration.nix
          ./configuration.nix
        ];
      };

      devShells.${system}.tinygrad = pkgs.callPackage ./tinygrad.nix { };

      # nix build /etc/nixos#NAME builds one of these alone, without the system.
      packages.${system} = {
        stprogr = pkgs.callPackage ./st/progr.nix { };
        stedgeai = pkgs.callPackage ./st/edgeai.nix { };
        stedgeai-patchelf = pkgs.callPackage ./st/edgeai-patchelf.nix { };
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
