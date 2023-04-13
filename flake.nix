{
  description = "A very basic flake";

  inputs = {
    nvim-vimrc-code.url = "github:argent0/flake-nvim-vimrc-code";
  };

  outputs = { self, nixpkgs, nvim-vimrc-code }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {

    packages.x86_64-linux.vimrc = pkgs.stdenv.mkDerivation {
      name = "vimrc";
      src = ./.;
      buildInputs = with pkgs; [
        nvim-vimrc-code.packages.x86_64-linux.vimrc
      ];
      installPhase = ''
        mkdir -p $out
        cat \
        ${./lua-start} \
        ${./treesitter.lua} \
        ${./lspconfig.lua} \
        ${./lua-end}  > $out/vimrc
      '';
    };

    lib = let
      vimrcPath = "${self.packages.x86_64-linux.vimrc}/vimrc";
      extraVimrcLines = builtins.readFile vimrcPath;
    in {
      version = "1.0.0";
      neovimForPython = {
        python ? pkgs.python311,
        pythonPackages ? pkgs.python311Packages,
        extraPythonPackages ? [ ],
        extraVimrcLines ? "",
        extraVimPlugins ? [ ],
        extraNixDerivations ? [ ],
      }: nvim-vimrc-code.lib.neovim {
        extraVimrcLines = extraVimrcLines;
        extraVimPlugins = with pkgs.vimPlugins; [
          vim-surround
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          (nvim-treesitter.withPlugins (p: with p; [ python ]))
        ] ++ extraVimPlugins;
        extraNixDerivations = [
          python
        ] ++ extraNixDerivations ++ (with pythonPackages; [
          mypy
          pylint
          python-lsp-server
          pylsp-mypy
        ]) ++ extraPythonPackages;
      };
    };
        

    devShells.x86_64-linux.default = self.lib.neovimForPython { };

    packages.x86_64-linux.default = pkgs.buildEnv {
      name = "nvim-python";
      paths = [];
    };

  };
}
