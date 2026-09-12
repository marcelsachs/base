{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.vim ];
  environment.variables.EDITOR = "vim";
  environment.etc.vimrc.text = ''
    colorscheme lunaperche
    set background=dark
    set expandtab
    set hlsearch
    set ignorecase
    set incsearch
    set shiftwidth=4
    set tabstop=4
    syntax on

    autocmd TextYankPost * if v:event.operator ==# 'y'
          \ | call system("wl-copy", join(v:event.regcontents, "\n"))
          \ | endif
  '';
}
