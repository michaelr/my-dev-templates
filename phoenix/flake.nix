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
      inherit (pkgs) mkShell writeScriptBin;
      exec_bin = pkg: bin: "${pkgs.${pkg}}/bin/${bin}";

      db_up = writeScriptBin "db_up" ''
        #!/usr/bin/env bash
        ${exec_bin "postgresql" "pg_ctl"} -D ".direnv/postgres" -l ".direnv/postgres/postgres.log" start
        '';

      db_down = writeScriptBin "db_down" ''
        #!/usr/bin/env bash
        ${exec_bin "postgresql" "pg_ctl"} stop
        '';

      db_log = writeScriptBin "db_log" ''
        #!/usr/bin/env bash
        ${exec_bin "tailspin" "tspin"} -f .direnv/postgres/postgres.log
        '';

    in
    {
      devShell = pkgs.mkShell {
        buildInputs = (with pkgs; [ elixir sd postgresql esbuild ]) ++
          [ db_up db_down db_log ] ++
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
