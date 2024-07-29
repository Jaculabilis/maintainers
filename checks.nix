{
  self,
  nixosSystem,
  pkgs,
  ...
}:
let
  # A dummy package with no maintainer
  orphanPkg = pkgs.stdenv.mkDerivation {
    name = "dummy-unmaintained-package";
    installPhase = ''
      echo "dummy-unmaintained-package" > $out
    '';
    meta = {
      maintainers = [ ];
    };
  };

  # A dummy package with a maintainer
  parentPkg = pkgs.stdenv.mkDerivation {
    name = "dummy-maintained-package";
    buildInputs = [ orphanPkg ];
    installPhase = ''
      echo "dummy-maintained-package" > $out
    '';
    meta = {
      maintainers = [ { github = "github"; } ];
    };
  };

  # A dummy NixOS config with an unmaintained package in its closure
  config = nixosSystem {
    inherit (pkgs) system;
    modules = [
      (
        { ... }:
        {
          environment.systemPackages = [ parentPkg ];
          # Boilerplate so nixosSystem compiles
          fileSystems."/" = {
            device = "/dev/dvd";
            fsType = "ext4";
          };
          boot.loader.grub.device = "/dev/dvd";
          system.stateVersion = "24.05";
        }
      )
    ];
  };

  inherit (self.bundlers.${pkgs.system}) all unmaintained;

  grepCheck =
    name: search: target:
    pkgs.runCommandLocal name { } ''
      wc -l ${target} >> test.log
      grep ${search} ${target} >> test.log
      cp test.log $out
    '';
in
{
  package = grepCheck "package" orphanPkg.name (unmaintained orphanPkg);
  packageClosure = grepCheck "packageClosure" orphanPkg.name (unmaintained parentPkg);
  configClosure = grepCheck "configClosure" orphanPkg.name (unmaintained config);
}
