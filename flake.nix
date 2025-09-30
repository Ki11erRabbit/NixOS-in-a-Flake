{
  description = "The Core of NixOS in a Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    flake-modules.url = "github:Ki11erRabbit/NixOS-in-a-Flake-Modules";
  };

  outputs = { self, flake-modules, ... }: let 
    mergeModules = resList: lib.foldl' (a: b: lib.recursiveUpdate a b) {} resList;
    modulesList = import ./modules.nix { inherit flake-modules; };
  in {
    nixSystem = { system, modules, pkgs, systemName }: let 
        mergedModules = mergeModules { inherit modules; };
        lib = pkgs.lib;
        evalModules = map (m: if builtins.isFunction m then m { inherit pkgs lib mergedModules; } else m) modulesList;
        systemPackages = pkgs.buildEnv {
            name = systemName;
            paths = pkgs.lib.concatMappAttrs (_: v: v // []) (map (m: m.packages or {}) modulesList);
        };
    in {
        defaultPrograms.${system} = evalModules.packages;
        apps.${system}.rebuild = let 
            script = pkgs.writeShellApplication {
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
                            for resName in "$RESOURCES_PROFILE"/*/; do
                                resDir=$(basename "$resName")
                              mkdir -p "/etc/$resDir"
                              cp -r "$resName/"* "/etc/$resDir/"
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
                            for resName in "$GEN"/*/; do
                              resDir=$(basename "$resName")
                              mkdir -p "/etc/$resDir"
                              cp -r "$GEN/$resName/"* "/etc/$resDir/"
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
            in {
                type = "app";
                program = "${script}/bin/rebuild";
            };
    }
  }
}
