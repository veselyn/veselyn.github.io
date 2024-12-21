{
  description = "veselyn.github.io";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts/main";
    treefmt-nix.url = "github:numtide/treefmt-nix/main";
    devenv.url = "github:cachix/devenv/main";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({self, ...}: {
      systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];

      imports = [
        ./dev/prettier-plugin-liquid
      ];

      perSystem = {
        config,
        pkgs,
        self',
        ...
      }: let
        gems = pkgs.bundlerEnv {
          name = "veselyn.github.io";
          gemdir = builtins.path {
            name = "veselyn.github.io";
            path = ./.;
          };
        };
        ruby = pkgs.ruby // gems.wrappedRuby;

        treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";

          programs = {
            alejandra.enable = true;
            prettier = {
              enable = true;
              settings.overrides = [
                {
                  files = "*.html";
                  options.parser = "liquid-html";
                }
              ];
              settings.plugins = [self'.packages.prettier-plugin-liquid.indexJs];
            };
          };
        };
      in {
        devShells.default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;

          modules = [
            {
              env = {
                BUNDLE_FORCE_RUBY_PLATFORM = true;
              };

              languages = {
                nix.enable = true;
                ruby.enable = true;
                ruby.package = ruby;
              };

              packages = [
                gems
                self'.formatter
              ];

              pre-commit.hooks = {
                deadnix.enable = true;
                statix.enable = true;
                treefmt.enable = true;
                treefmt.package = self'.formatter;
              };
            }
          ];
        };

        packages = {
          devenv-test = self'.devShells.default.config.test;
          devenv-up = self'.devShells.default.config.procfileScript;
        };

        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;
      };
    });
}
