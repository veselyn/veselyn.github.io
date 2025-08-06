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
        name = "veselyn.github.io";

        gems = pkgs.bundlerEnv {
          inherit name;
          gemdir = builtins.path {
            inherit name;
            path = ./.;
          };
        };

        env = {
          BUNDLE_FORCE_RUBY_PLATFORM = true;
        };

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

          settings.global.excludes = [
            "_sass/terminal.scss"
          ];
        };
      in {
        devShells.default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;

          modules = [
            {
              env = {
                inherit (env) BUNDLE_FORCE_RUBY_PLATFORM;
              };

              languages = {
                nix.enable = true;
              };

              packages = [
                gems
                pkgs.bundix
                pkgs.git
                self'.formatter
              ];

              git-hooks.hooks = {
                deadnix.enable = true;
                statix.enable = true;
                treefmt.enable = true;
                treefmt.package = self'.formatter;
              };

              processes = {
                site.exec = "jekyll serve";
              };

              scripts = {
                build-site.exec = "JEKYLL_ENV=development jekyll build";
              };
            }
          ];
        };

        packages = {
          devenv-test = self'.devShells.default.config.test;
          devenv-up = self'.devShells.default.config.procfileScript;
        };

        apps = {
          build-site = {
            type = "app";
            program = pkgs.writeShellApplication {
              name = "build-site";
              runtimeInputs = [gems];
              text = ''
                export JEKYLL_ENV=production
                export JEKYLL_GITHUB_TOKEN=$GITHUB_TOKEN
                export PAGES_REPO_NWO=$GITHUB_REPOSITORY
                jekyll build
              '';
            };
          };
        };

        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;
      };
    });
}
