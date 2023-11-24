{
  description = "A Nix-flake-based Elixir development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    }:

    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShell = pkgs.mkShell {
        buildInputs = (with pkgs; [ elixir sd postgresql esbuild ]) ++
          pkgs.lib.optionals (pkgs.stdenv.isLinux) (with pkgs; [ gigalixir inotify-tools libnotify ]) ++ # Linux only
          pkgs.lib.optionals (pkgs.stdenv.isDarwin) ((with pkgs; [ terminal-notifier ]) ++ # macOS only
            (with pkgs.darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]));

        shellHook = ''
          ${pkgs.elixir}/bin/mix --version
          ${pkgs.elixir}/bin/iex --version
        '';
      };
    });
}
