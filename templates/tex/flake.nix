{
  description = "A simple LaTeX template for writing documents with latexmk";
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05"; };
  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSupportedSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSupportedSystems (system:
        let pkgs = import nixpkgs { system = system; };
        in {
          default = pkgs.stdenv.mkDerivation {
            name = "pdf";
            src = ./.;
            buildInputs = [ pkgs.texliveFull ];
            buildPhase = ''
              just build 
            '';
            installPhase = ''
              just install INSTALL_DIR=$out
            '';

          };
        });
    };
}
