{ pkgs, ... }:
let
  vimrc = pkgs.writeText "vimrc" ''
    colorscheme lunaperche
    set background=dark
    set expandtab
    set hlsearch
    set ignorecase
    set incsearch
    set shiftwidth=4
    set tabstop=4
    syntax on
    autocmd TextYankPost * call system("wl-copy", @")
  '';
in
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vim" ''
      exec ${pkgs.vim}/bin/vim -u ${vimrc} "$@"
    '')
  ];
  environment.variables.EDITOR = "vim";
}
