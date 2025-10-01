{
  description = "The Core of NixOS in a Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    flake-modules.url = "github:Ki11erRabbit/NixOS-in-a-Flake-Modules";
  };

  outputs = { self, flake-modules, ... }: {
    nixSystem = { system, modules, pkgs, systemName }: let 
        lib = pkgs.lib;
        modulesList = (import ./modules.nix {inherit pkgs lib; }).modules;
        config = flake-modules.lib.mkMerge modules;
        evalModules = map (m: if builtins.isFunction m then m { inherit pkgs lib config flake-modules; } else {}) modulesList;
        hooks = map (m: m.hooks or "") evalModules;
        
        mainHookScriptText = ''
        #!${pkgs.stdenv.shell}
        set -e
        '' + lib.concatStrings hooks;
        mainHookScript = pkgs.writeShellScriptBin "mainHookScript" mainHookScriptText;

        systemPackages = pkgs.buildEnv {
            name = systemName;
            paths = lib.concatMap (m: m.packages or []) evalModules;
        };
    in {
        packages.${system}.default = systemPackages;

        apps.${system}.rebuild = let 
            script = pkgs.writeShellApplication {
                name = "rebuild";
                text = ''
                        set -euo pipefail
                        sudo nix build .
                        echo "hello"
                        echo "${mainHookScript}/bin/mainHookScript"
                        echo ran hooks
                    '';
                };
            in {
                type = "app";
                program = "${script}/bin/rebuild";
            };
    };
  };
}
