{
  description = "The Core of NixOS in a Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    flake-modules.url = "github:Ki11erRabbit/NixOS-in-a-Flake-Modules";
  };

  outputs = { self, flake-modules, ... }: {
    mkNixSystem = { system, modules, pkgs, systemName }: let
        lib = pkgs.lib;
        modulesList = (import ./modules.nix {inherit pkgs lib; }).allModules;

        result = lib.fix (self: let
            config = flake-modules.lib.mkMerge modules;

            evalModules = map (m: if builtins.isFunction m then m { inherit pkgs lib config flake-modules; } else {}) modulesList;
            in {
                inherit config evalModules;
                hookTexts = map (m: m.hooks or "") evalModules;
                

                systemPackages = pkgs.buildEnv {
                    name = systemName;
                    paths = lib.concatMap (m: m.packages or []) evalModules;
                };
            });
    in {
        packages.${system}.${systemName} = result.systemPackages;

    };
  };
  availConfig = { systems, pkgs }: let 
    lib = pkgs.lib;
  in {
        packages = flake-modules.lib.mkMerge systems;

        apps.${system}.rebuild = let 
            script = pkgs.writeShellApplication {
                name = "rebuild";
                text = ''
                        set -euo pipefail
                        command="switch"
                        system=""
                        #if [ $# -gt 0 ]; then cmd="$1"; shift; fi
                        if [ $# -gt 0 ]; then system="$1"; shift; fi
                        sudo nix build ".#$system"
                        ${lib.concatStrings result.hookTexts}
                    '';
                };
            in {
                type = "app";
                program = "${script}/bin/rebuild";
            };
  };
}
