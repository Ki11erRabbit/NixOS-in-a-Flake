{ config, pkgs, lib, ... }:
lib.mkIf (config.services.dummy.enable or false) {
    packages = [];
    
    resources = {
        dummy = {
            config.text = ''
            Hello, World!
            '';
        };
    };
}
