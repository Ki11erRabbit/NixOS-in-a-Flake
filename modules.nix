{ pkgs, lib, ... }:
let 
    allModules = [
        (import ./modules/dummy.nix)
    ];
in {
    modules = allModules;
}
