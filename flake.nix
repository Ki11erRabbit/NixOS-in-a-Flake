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
        #mergeModules = resList: lib.foldl' (a: b: lib.recursiveUpdate a b) {} resList;
        config = flake-modules.lib.mkMerge modules;
        evalModules = map (m: if builtins.isFunction m then m { inherit pkgs lib config; } else {}) modulesList;
        systemPackages = pkgs.buildEnv {
            name = systemName;
            paths = lib.concatMap (m: m.packages or []) evalModules;
        };
        hookScripts = map (m: "\n${m.hookscript}/bin/hookscript") evalModules;
        hookScriptText = ''
        #!${pkgs.stdenv.shell}
        set -e
        '' + lib.concatStrings hookScripts;
        hookScript = pkgs.writeShellScriptBin "hookScript" hookScriptText;
    in {
        packages.${system} = systemPackages;
        apps.${system}.rebuild = let 
            script = pkgs.writeShellApplication {
                name = "rebuild";
                text = ''
                        set -euo pipefail
                        sudo nix build .
                        ${hookScript}/bin/hookScript
                    '';
                };
            in {
                type = "app";
                program = "${script}/bin/rebuild";
            };
    };
  };
}
