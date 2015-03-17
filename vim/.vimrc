set nocompatible
filetype off

set runtimepath+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
call vundle#end()
filetype plugin indent on

set encoding=utf-8
set fileencoding=utf-8
syntax enable
syntax on

au BufNewFile,BufRead *.md set filetype=markdown

au FileType python set expandtab
au FileType sh set expandtab
au FileType tex set expandtab
au FileType scheme set expandtab
au FileType scheme set lisp
au FileType c set expandtab
au FileType cpp set expandtab
au FileType asm set expandtab

set laststatus=2
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

if filereadable("cscope.out")
	cs add cscope.out
endif

nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>r :cs reset<CR>

nnoremap tn :tabnext<CR>
nnoremap tp :tabprev<CR>

Plugin 'fatih/vim-go'
Plugin 'Lokaltog/vim-powerline'
Plugin 'scrooloose/nerdtree'
