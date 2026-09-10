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

      formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
