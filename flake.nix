{
  description = "tools for building latex files";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      mkLatexTools = (import ./default.nix);
    in
      (flake-utils.lib.eachSystem flake-utils.lib.allSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          latexTools = mkLatexTools { inherit pkgs nixpkgs; };
        in rec
        {
          packages = {};
          devShell = pkgs.mkShell
            {
              packages = latexTools.deps;
              LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
              shellHook = ''
                . ${latexTools.latexShellInit}

                echo "for any latex file, you can use:"
                echo " - 'latex_builder build foo.tex' to build dist/foo.pdf"
                echo " - 'latex_builder watch foo.tex' to build automatically on file change."
              '';
            };
        }
      )) // {
        lib = {
          inherit mkLatexTools;
        };
      };

}
