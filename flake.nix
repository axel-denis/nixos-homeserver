{
  description = "Home Server Service Modules";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      lib = import ./lib { inherit (pkgs) lib; };
    in {
      nixosModules = {
        imports = [ ./modules/immich.nix ./modules/jellyfin.nix ];
      };
    };
}
