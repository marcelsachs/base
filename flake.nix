{
  description = "base";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    tinygrad = {
      url = "github:tinygrad/tinygrad";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";
      blackwell =
        extra:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            inputs.determinate.nixosModules.default
            ./hardware-configuration.nix
            ./modules
            extra
          ];
        };
    in
    {
      nixosConfigurations.blackwell = blackwell { };
      nixosConfigurations.blackwell-bare = blackwell { stick.enable = false; };

      formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
