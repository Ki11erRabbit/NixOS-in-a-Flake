{ config, pkgs, lib, flake-modules, ... }:

if config.services.dummy.enable or false then

flake-modules.mkOption ({
    packages = [];
    files = [
        {
            name = "dummy.txt";
            location = /etc/dummy;
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
    packages = [];
    files = [
    ];
    hooks = [
        "echo 'goodbye world'"
    ];
})
