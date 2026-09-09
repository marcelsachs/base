{
  description = "base";

  inputs = {
    # 0.1 = rolling. 5060 Ti nvidia.
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    # Do not follows nixpkgs onto determinate: cache miss.
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
