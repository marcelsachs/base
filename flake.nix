{
  description = "base";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    tinygrad = {
      url = "github:tinygrad/tinygrad";
      flake = false;
    };
    # Private repo, fetched over ssh with sachs's key: build as sachs, nixos-rebuild --sudo.
    stm32n6 = {
      url = "git+ssh://git@github.com/marcelsachs/stm32n6";
      flake = false;
    };
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
        specialArgs = { inherit inputs; };
        modules = [
          inputs.determinate.nixosModules.default
          ./hardware-configuration.nix
          ./configuration.nix
        ];
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
