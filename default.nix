params:
let
  pkgs = params.pkgs;
  nixpkgs = params.nixpkgs;
  lib = nixpkgs.lib;
  texPkgs = params.texPkgs or [
    "scheme-small"
    "unicode-math"
    "svg" "trimspaces" "catchfile"
    "transparent"
    "latex-bin" "latexmk"
    "lualatex-math"
    "selnolig"
    "enumitem"
    "wrapfig"
    "extsizes" "euenc" "tools"
    "hyperref" "pdftexcmds" "infwarerr"
    "kvoptions" "l3kernel" "zref"
    "fontspec"
    "libertine"
    "geometry" "titling" "mathabx" "csquotes"
    "standalone" "cleveref" "ebproof"
    "appendix"
    "svn-prov"
    "luatex85"
    "minibox" "pbox" "mdframed" "needspace" "adjustbox"
    "lstaddons"
    "biblatex"
    "beamer"
    "cyrillic"
    "babel-bulgarian" "babel-english"
  ];
  extraBuildDeps = params.extraBuildDeps or [];
  tex-megapkg = pkgs.texlive.combine (lib.getAttrs texPkgs pkgs.texlive);
  fontPkgs = params.fontPkgs or [
    pkgs.noto-fonts
    pkgs.stix-two
    (pkgs.nerdfonts.override { fonts = [ "DroidSansMono" ]; })
  ];
  fontConfigFile = pkgs.makeFontsConf {
    fontDirectories = fontPkgs;
  };
  fontDir = pkgs.symlinkJoin {
    name = "fonts";
    paths = fontPkgs;
  };
  latexBuilderScript = pkgs.stdenvNoCC.mkDerivation rec {
    name = "latex-build-script";
    src = ./.;
    phases = [ "unpackPhase" "installPhase" "fixupPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp -rf build.sh $out/bin/latex_builder
      chmod +x $out/bin/latex_builder
    '';
  };
  latexShellInit = pkgs.writeTextFile {
    name = "latex_shell_init.sh";
    text = ''
      if [[ -w /tmp ]]; then
        latex_cache_dir=/tmp/latex_cache
      else
        latex_cache_dir=.latex-cache
      fi

      mkdir -p "''${latex_cache_dir}"/texmf-var
      export TEXMFHOME="''${latex_cache_dir}" TEXMFVAR="''${latex_cache_dir}"/texmf-var

      # xelatex and pdflatex use FONTCONFIG_FILE to look up fonts
      export FONTCONFIG_FILE=${fontConfigFile}

      # lualatex builds a font cache using $OSFONTDIR
      export OSFONTDIR=${fontDir}/share/fonts
    '';
    executable = true;
    destination = "";
  };
  deps = [
    tex-megapkg
    pkgs.biber
    pkgs.ncurses
    pkgs.inkscape
    latexBuilderScript
  ] ++ extraBuildDeps;
  buildLatex = { pkgname, latexFiles, src }: pkgs.stdenvNoCC.mkDerivation rec {
    name = pkgname;
    inherit src;
    buildInputs = [
      pkgs.coreutils
      pkgs.bash
      latexBuilderScript
    ] ++ deps;
    phases = ["unpackPhase" "buildPhase" "installPhase"];
    buildPhase = ''
      . ${latexShellInit}

      latex_builder build ${latexFiles}
    '';
    installPhase = ''
      mkdir -p $out
      cp -f dist/*.pdf $out/
    '';
  };
in {
  inherit latexBuilderScript buildLatex deps latexShellInit;
}
