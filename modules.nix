{ pkgs, lib, config, ... }:
let 
    allModules = [
        (import ./modules/dummy.nix { inherit pkgs lib config; })
    ];
in
    lib.mkMerge allModules
