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
      lib = forAllSystems (system: import ./lib.nix { pkgs = nixpkgsFor.${system}; });

      bundlers = forAllSystems (
        system:
        let
          inherit (self.lib.${system}) allMaintainers expandInput noMaintainers;
        in
        {
          default = self.bundlers.${system}.unmaintained;
          all = drv: allMaintainers (expandInput drv);
          unmaintained = drv: noMaintainers (expandInput drv);
        }
      );

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt-rfc-style);

      checks = forAllSystems (
        system:
        import ./checks.nix {
          inherit self;
          inherit (nixpkgs.lib) nixosSystem;
          pkgs = nixpkgsFor.${system};
        }
      );
    };
}
