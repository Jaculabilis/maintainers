{
  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
      system = "x86_64-linux";
    in
    {
      bundlers = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          lib = import ./lib.nix { inherit pkgs; };
          inherit (lib) allMaintainers expandInput noMaintainers;
        in
        {
          default = self.bundlers.${system}.unmaintained;
          all = drv: allMaintainers (expandInput drv);
          unmaintained = drv: noMaintainers (expandInput drv);
        }
      );

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt-rfc-style);
    };
}
