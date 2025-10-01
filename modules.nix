{ pkgs, lib, ... }:
let 
    allModules = [
        (import ./modules/dummy.nix)
        (import ./modules/gnome.nix)
    ];
in {
    allModules = allModules;
}
