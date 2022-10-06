# michaelr's nix dev templates

Acknowledgements to Luc Perkins.

See https://determinate.systems/posts/nix-direnv

Note: this is for my own personal use but feel free to steal from it.

## Usage

```shell
mkdir new-elixir-project && cd new-elixir-project
nix flake init -t "github:michaelr/my-dev-templates#elixir"
direnv allow
```

## Show Templates

```shell
nix flake show "github:michaelr/my-dev-templates"
```
