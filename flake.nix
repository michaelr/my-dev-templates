{
  description =
    "Flake based dev templates. Based on Luc Perkins - github:the-nix-way/dev-templates";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:
    {
      templates = {
        elixir = {
          path = ./elixir;
          description = "Elixir development environment";
        };
        node = {
          path = ./node;
          description = "Node.js development environment";
        };
        phoenix = {
          path = ./phoenix;
          description = "Elixir/Phoenix development environment";
        };

      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) mkShell writeScriptBin;
        exec = pkg: "${pkgs.${pkg}}/bin/${pkg}";

        format = writeScriptBin "format" ''
          ${exec "nixpkgs-fmt"} **/*.nix
        '';

        update = writeScriptBin "update" ''
          for dir in `ls -d */`; do # Iterate through all the templates
            (
              cd $dir
              ${exec "nix"} flake update # Update flake.lock
              ${
                exec "direnv"
              } reload    # Make sure things work after the update
            )
          done
        '';
      in
      {
        devShells = { default = mkShell { buildInputs = [ format update ]; }; };
      });
}
