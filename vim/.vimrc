set shell=bash
set nocompatible
filetype off

set runtimepath+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'kchmck/vim-coffee-script'
Plugin 'fatih/vim-go'
Plugin 'dag/vim-fish'
Plugin 'vim-erlang/vim-erlang-runtime'
call vundle#end()
filetype plugin indent on
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
let g:vim_markdown_folding_disabled = 1
Plugin 'Lokaltog/vim-powerline'
Plugin 'scrooloose/nerdtree'
Plugin 'flazz/vim-colorschemes'
Plugin 'leafgarland/typescript-vim'

syntax enable
syntax on

set encoding=utf-8
set fileencoding=utf-8

autocmd BufNewFile,BufReadPost *.md set filetype=markdown

"au BufNewFile,BufRead *.md set expandtab
"au BufNewFile,BufRead *.go set filetype=go
"au BufNewFile,BufRead *.gemspec set filetype=ruby
"au BufNewFile,BufRead *.ts set syntax=typescript
"au BufNewFile,BufRead *.coffee set syntax=coffee

au FileType makefile set noexpandtab
au FileType python set indentkeys-=<:>
au FileType scheme set lisp

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
set expandtab

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

set t_Co=256
colorscheme molokai
