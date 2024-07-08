{ pkgs, ... }:
let
  inherit (builtins)
    hasAttr
    head
    length
    map
    match
    tail
    ;
  inherit (pkgs) runCommandLocal writeText;
  inherit (pkgs.lib)
    concatLines
    concatStringsSep
    filter
    ;
  inherit (import ./closure.nix { inherit pkgs; }) drvClosure;
in
rec {
  maintainable = drv: hasAttr "meta" drv && hasAttr "maintainers" drv.meta;
  drvMaintainers = drv: if maintainable drv then drv.meta.maintainers else [ ];

  # Construct a link to a derivation's source in github:NixOS/nixpkgs
  drvSource =
    drv:
    let
      parts = match "/nix/store/[^/]+/(.*):([0-9]*)" drv.meta.position;
    in
    if hasAttr "meta" drv && hasAttr "position" drv.meta then
      "https://github.com/NixOS/nixpkgs/blob/master/${head parts}#L${head (tail parts)}"
    else
      "";

  mainInfo = drv: {
    name = drv.name;
    maintainers = map (main: toString main.github) (drvMaintainers drv);
    source = drvSource drv;
  };

  stringJoin = objToString: objs: writeText "txt" (concatLines (map objToString objs));

  closureInfo = drv: map mainInfo (filter maintainable (drvClosure drv));

  allMaintainers =
    drv:
    let
      info = closureInfo drv;
      infoToString = info: "${info.name} ${concatStringsSep "," info.maintainers}";
    in
    runCommandLocal "all-maintainers.txt" { } ''
      <${stringJoin infoToString info} sort -u | ${pkgs.unixtools.column}/bin/column -t > $out
    '';

  noMaintainers =
    drv:
    let
      info = closureInfo drv;
      unmaintained = filter (info: (length info.maintainers) == 0) info;
      infoToString = info: "${info.name} ${info.source}";
    in
    runCommandLocal "unmaintained.txt" { } ''
      <${stringJoin infoToString unmaintained} sort -u | ${pkgs.unixtools.column}/bin/column -t > $out
    '';

  expandInput =
    input:
    if (input.class or null == "nixos") && (input._type or null == "configuration") then
      [
        input.config.system.build.toplevel
        input.config.environment.systemPackages
      ]
    else
      input;
}
