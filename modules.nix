{ pkgs, lib, ... }:
let 
    allModules = [
        (import ./modules/dummy.nix)
    ];
in {
    allModules = allModules;
}
