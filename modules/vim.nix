{ pkgs, ... }:
let
  # -S after normal startup. -u replaces $VIM/vimrc, which is what
  # broke Backspace (that file already sets nocompatible/backspace).
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
    autocmd TextYankPost * if v:event.operator ==# 'y' | call system("wl-copy", join(v:event.regcontents, "\n")) | endif
  '';
in
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vim" ''
      exec ${pkgs.vim}/bin/vim -S ${vimrc} "$@"
    '')
  ];
  environment.variables.EDITOR = "vim";
}
