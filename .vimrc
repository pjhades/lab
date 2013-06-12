syntax enable
syntax on

set fileencoding=utf8

filetype indent on

set background=dark
set t_Co=256
let g:solarized_termcolors=256
let g:solarized_termtrans=1
colorscheme solarized


au FileType python set expandtab
au FileType sh set expandtab
au FileType tex set expandtab
au FileType scheme set expandtab
au FileType scheme set lisp
au FileType c set expandtab
au FileType cpp set expandtab

set nocompatible
set laststatus=2
let g:Powerline_symbols = 'unicode'

set number
set ruler
set showcmd
set incsearch
set nowrapscan
set nobackup
set nowrap

set autoindent

set shiftwidth=4
set tabstop=4
