{
  description = "The Core of NixOS in a Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    flake-modules.url = "github:Ki11erRabbit/NixOS-in-a-Flake-Modules";
  };

  outputs = { self, flake-modules, ... }: {
  nixSystem = { system, modules, pkgs, systemName }: let
  lib = pkgs.lib;

  # 1️⃣ Import all flake-provided modules
  modulesList = (import ./modules.nix { inherit pkgs lib; }).allModules;

  # 2️⃣ Merge user input modules
  config = flake-modules.lib.mkMerge modules;

  # 3️⃣ Evaluate all modules (they can reference config)
  evalModules = map (m: if builtins.isFunction m then m { inherit pkgs lib config flake-modules; } else {}) modulesList;

  # 4️⃣ Collect plain hook text from modules only
  hookTexts = map (m: m.hooks or "") evalModules; 

  # 6️⃣ Build system packages
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
        ${lib.concatStrings hookTexts}
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
