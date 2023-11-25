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

      proj_init = writeScriptBin "proj_init" ''
        #!/usr/bin/env bash
        set -eu
        if [ -d .mix ]; then
          echo ".mix/ already exists. $0 was probably already run. Exiting."
          exit 1
        fi

        ${exec_bin "elixir" "mix"} local.hex --force
        ${exec_bin "elixir" "mix"} archive.install hex phx_new --force

        yes 2>/dev/null | ${exec_bin "elixir" "mix"} phx.new . --live

        # setup dev config to use $PGDATA to connect to the database
        ${exec_bin "sd" "sd"} -f m \
            'username: "postgres",\n\s+password: "postgres",\n\s+hostname: "localhost",' \
            'socket_dir: System.get_env("PGDATA"),' \
            config/dev.exs

        db_up # start postgres

        ${exec_bin "elixir" "mix"} setup
        ${exec_bin "elixir" "mix"} phx.server
        '';

    in
    {
      devShell = pkgs.mkShell {
        buildInputs = (with pkgs; [ elixir postgresql esbuild ]) ++
          [ db_up db_down db_log proj_init ] ++
          pkgs.lib.optionals (pkgs.stdenv.isLinux) (with pkgs; [ gigalixir inotify-tools libnotify ]) ++ # Linux only
          pkgs.lib.optionals (pkgs.stdenv.isDarwin) ((with pkgs; [ terminal-notifier ]) ++ # macOS only
            (with pkgs.darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]));

        shellHook = ''
          ${pkgs.elixir}/bin/mix --version
          ${pkgs.elixir}/bin/iex --version
          export MIX_HOME=$(pwd)/.mix
        '';
      };
    });
}
