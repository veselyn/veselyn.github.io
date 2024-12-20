_: {
  perSystem = {pkgs, ...}: {
    packages.prettier-plugin-liquid = let
      drv = pkgs.stdenv.mkDerivation {
        pname = "prettier-plugin-liquid";
        version = "1.6.3";

        src = builtins.path {
          name = "prettier-plugin-liquid";
          path = ./.;
          filter = path: _type:
            builtins.elem (/. + path) [
              ./package.json
              ./package-lock.json
            ];
        };

        nativeBuildInputs = builtins.attrValues {
          inherit
            (pkgs)
            cacert
            nodejs
            ;
        };

        buildPhase = ''
          HOME=$TMPDIR npm ci
        '';

        installPhase = ''
          mkdir -p "$out"
          cp -r ./node_modules "$out"
        '';

        outputHashMode = "recursive";
        outputHash = "sha256-YUviaCGKGYqlJUpTPkzZdJcfQQgUoSj565+dhommsRY=";
      };
    in
      drv
      // {
        indexJs = "${drv}/node_modules/@shopify/prettier-plugin-liquid/dist/index.js";
      };
  };
}
