{
  description = "The Core of NixOS in a Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    flake-modules.url = "github:Ki11erRabbit/NixOS-in-a-Flake-Modules";
  };

  outputs = { self, nixpkgs, flake-modules, ... }: 
  let 
    lib = nixpkgs.lib;

    mergeResources = resList: lib.foldl' (a: b: lib.recursiveUpdate a b) {} resList;

    modules = import ./modules.nix { inherit flake-modules; };
  in {
      setup = { pkgs, config, system, systemName, ... }: let 
        evalModules = { modules, pkgs, systemName, config }:
            let 
                evaluated = map (m:
                    if builtins.isFunction m then m { inherit pkgs lib config; } else m
                ) modules;
                
                mergedResources = mergeResources (map (m: m.resources or {}) evaluated);

                systemPackages = pkgs.buildEnv {
                    name = systemName;
                    paths = lib.concatMappAttrs (_: v: v // []) (map (m: m.packages or {}) evaluated);
                };
            in {
                packages = systemPackages;
                resources = mergedResources;
            };
      in {
        defaultPackages."${system}" = evalModules { inherit modules pkgs systemName; };

        apps."${system}" = {
                rebuild = {
                    type = "app";
                    program = pkgs.writeShellApplication {
                        name = "rebuild";
                        text = ''
                            set -euo pipefail
                            cmd="switch"
                            if [ $# -gt 0 ]; then cmd="$1"; shift; fi

                            SYSTEM_PROFILE="/nix/var/nix/profiles/system"
                            RESOURCES_PROFILE="/nix/var/nix/profiles/resources"

                            case "$cmd" in
                              build)
                                nix build .#system -o ./result-system
                                nix build .#resources -o ./result-resources
                                ;;
                              switch)
                                nix build .#system -o "$SYSTEM_PROFILE"
                                nix build .#resources -o "$RESOURCES_PROFILE"

                                echo "Syncing resources..."
                                for resName in $(ls "$RESOURCES_PROFILE"); do
                                  mkdir -p "/etc/$resName"
                                  cp -r "$RESOURCES_PROFILE/$resName/"* "/etc/$resName/"
                                done
                                ;;
                              dry-run)
                                nix build .#system
                                nix build .#resources
                                echo "Dry-run complete"
                                ;;
                              rollback)
                                nix-env --profile "$SYSTEM_PROFILE" --rollback || true
                                nix-env --profile "$RESOURCES_PROFILE" --rollback || true
                                GEN=$(readlink -f "$RESOURCES_PROFILE")
                                for resName in $(ls "$GEN"); do
                                  mkdir -p "/etc/$resName"
                                  cp -r "$GEN/$resName/"* "/etc/$resName/"
                                done
                                ;;
                              list-generations)
                                echo "--- System ---"
                                nix-env --list-generations --profile "$SYSTEM_PROFILE" || true
                                echo "--- Resources ---"
                                nix-env --list-generations --profile "$RESOURCES_PROFILE" || true
                                ;;
                              *)
                                echo "Usage: nix run .#rebuild [build|switch|dry-run|rollback|list-generations]"
                                exit 1
                                ;;
                            esac
                        '';
                    };
                };
            };
      };
  };
}
