# based on: https://github.com/brendanzab/ocaml-flake-example/blob/main/flake.nix
{
  description = "ChangeLog Generator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems }:
    let
      lib = nixpkgs.lib;
      eachSystem = lib.genAttrs (import systems);
    in
    {
      # Exposed packages that can be built or run with `nix build` or
      # `nix run` respectively:
      #
      #     $ nix build .#<name>
      #     $ nix run .#<name> -- <args?>
      #
      packages = eachSystem (system:
        let
          legacyPackages = nixpkgs.legacyPackages.${system};
          ocamlPackages = legacyPackages.ocamlPackages;
        in
        {
          # The package that will be built or run by default. For example:
          #
          #     $ nix build
          #     $ nix run -- <args?>
          #
          default = self.packages.${system}.clg;

          clg = ocamlPackages.buildDunePackage {
            pname = "clg";
            version = "0.1.0";
            duneVersion = "3";
            src = ./.;

            buildInputs = [
              ocamlPackages.yaml
              ocamlPackages.clap
            ];

            strictDeps = true;
          };
        });

      # Flake checks
      #
      #     $ nix flake check
      #
      checks = eachSystem (system:
        let
          legacyPackages = nixpkgs.legacyPackages.${system};
          ocamlPackages = legacyPackages.ocamlPackages;
        in
        {
          clg =
            let
              patchDuneCommand =
                let
                  subcmds = [ "build" "test" "runtest" "install" ];
                in
                lib.replaceStrings
                  (lib.lists.map (subcmd: "dune ${subcmd}") subcmds)
                  (lib.lists.map (subcmd: "dune ${subcmd} --display=short") subcmds);
            in

            self.packages.${system}.clg.overrideAttrs
              (oldAttrs: {
                name = "check-${oldAttrs.name}";
                doCheck = true;
                buildPhase = patchDuneCommand oldAttrs.buildPhase;
                checkPhase = patchDuneCommand oldAttrs.checkPhase;
                # installPhase = patchDuneCommand oldAttrs.checkPhase;
              });

          dune-fmt = legacyPackages.runCommand "check-dune-fmt"
            {
              nativeBuildInputs = [
                ocamlPackages.dune_3
                ocamlPackages.ocaml
                legacyPackages.ocamlformat
              ];
            }
            ''
              echo "checking dune and ocaml formatting"
              dune build \
                --display=short \
                --no-print-directory \
                --root="${./.}" \
                --build-dir="$(pwd)/_build" \
                @fmt
              touch $out
            '';

          dune-doc = legacyPackages.runCommand "check-dune-doc"
            {
              ODOC_WARN_ERROR = "true";
              nativeBuildInputs = [
                ocamlPackages.dune_3
                ocamlPackages.ocaml
                ocamlPackages.odoc
              ];
            }
            ''
              echo "checking ocaml documentation"
              dune build \
                --display=short \
                --no-print-directory \
                --root="${./.}" \
                --build-dir="$(pwd)/_build" \
                @doc
              touch $out
            '';

          nixpkgs-fmt = legacyPackages.runCommand "check-nixpkgs-fmt"
            { nativeBuildInputs = [ legacyPackages.nixpkgs-fmt ]; }
            ''
              echo "checking nix formatting"
              nixpkgs-fmt --check ${./.}
              touch $out
            '';
        });

      devShells = eachSystem (system:
        let
          legacyPackages = nixpkgs.legacyPackages.${system};
          ocamlPackages = legacyPackages.ocamlPackages;
        in
        {
          default = legacyPackages.mkShell {
            # Development tools
            packages = [
              legacyPackages.nixpkgs-fmt
              legacyPackages.ocamlformat
              legacyPackages.fswatch
              ocamlPackages.odoc
              ocamlPackages.ocaml-lsp
              ocamlPackages.utop
            ] ++ self.packages.${system}.clg.buildInputs;

            # Tools from packages
            inputsFrom = [
              self.packages.${system}.clg
            ];
          };
        });
    };
}
