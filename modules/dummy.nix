{ config, pkgs, lib, flake-modules, ... }:
let 
    bad = builtins.trace (toString config) config;
in if config.services.dummy.enable or false then

flake-modules.lib.mkOption ({
    pkgs = pkgs;
    packages = [];
    files = [
        {
            name = "dummy.txt";
            location = "/etc/dummy";
            text = ''
Hello, World!
            '';
        }
    ];
    hooks = [
        "echo 'Hello, World!'"
    ];
})
else 
flake-modules.mkOption ({
    pkgs = pkgs;
    packages = [];
    files = [
    ];
    hooks = [
        "echo 'goodbye world'"
    ];
})
