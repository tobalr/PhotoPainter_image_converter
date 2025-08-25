{
  description = "PhotoPainter Image Convertert";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Minimal Python environment - pillow-heif pulls in OpenCV
        # Users can install it separately if HEIC support is needed
        pythonEnv = pkgs.python311.withPackages (ps: with ps; [
          pillow
          tqdm
        ]);
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "photopainter-image-converter";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = [ pythonEnv ];
          buildInputs = with pkgs; [ libjpeg libpng ];

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            mkdir -p $out/bin $out/share/photopainter
            cp -r * $out/share/photopainter/
            
            cat > $out/bin/photopainter-converter << EOF
#!/bin/sh
# Run from current directory so user can write output files
exec ${pythonEnv}/bin/python $out/share/photopainter/convert.py "\$@"
EOF
            chmod +x $out/bin/photopainter-converter
          '';
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
          name = "photopainter-converter";
        };
      });
}
