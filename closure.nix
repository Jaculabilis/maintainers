# MIT license, see below
#
# These are helper functions for determining buildtime closures.
# Sources:
# - https://github.com/NixOS/bundlers/blob/00762a03a3d862a2ca6272a21fdc50bda5d36c42/report/default.nix
# - https://nmattia.com/posts/2019-10-08-runtime-dependencies.html

{ pkgs, ... }:
let
  inherit (builtins) genericClosure hasAttr map;
  inherit (pkgs.lib)
    concatLists
    concatMap
    filter
    isDerivation
    isList
    mapAttrsToList
    ;

  # Map a drv or list of drvs to a list of output drvs
  drvOutputs =
    drv:
    if isList drv then
      concatMap drvOutputs drv
    else if hasAttr "outputs" drv then
      map (out: drv.${out}) drv.outputs
    else
      [ drv ];

  # Map a drv or list of drvs to the outputs of referenced derivations
  drvDeps =
    drv:
    if isList drv then
      concatMap drvDeps drv
    else
      mapAttrsToList (
        k: v:
        if isDerivation v then
          (drvOutputs v)
        else if isList v then
          concatMap drvOutputs (filter isDerivation v)
        else
          [ ]
      ) drv;
in
{
  # Get the reference closure of a derivation or list of derivations
  # This may miss dependencies that are only in-closure from string context
  drvClosure =
    let
      wrap = drv: {
        key = drv.outPath;
        inherit drv;
      };
    in
    drv:
    map (obj: obj.drv) (genericClosure {
      startSet = map wrap (drvOutputs drv);
      operator = obj: map wrap (concatLists (drvDeps obj.drv.drvAttrs));
    });
}

# MIT License
#
# Copyright (c) 2021 Nicolas Mattia, Tim Van Baak
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
