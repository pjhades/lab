syntax enable
syntax on

set fileencoding=utf8

filetype indent on

"set background=dark
set t_Co=256
let g:solarized_termcolors=256
let g:solarized_termtrans=1
colorscheme grb256

au BufNewFile,BufRead *.md set filetype=markdown
au BufNewFile,BufRead *.md set expandtab
au BufNewFile,BufRead *.go set filetype=go
au BufNewFile,BufRead *.s,*.S set filetype=asm

au FileType python set expandtab
au FileType sh set expandtab
au FileType tex set expandtab
au FileType scheme set expandtab
au FileType scheme set lisp
au FileType c set expandtab
au FileType cpp set expandtab
au FileType lua set expandtab
au FileType go set expandtab
au FileType asm set expandtab


set nocompatible
set laststatus=2
"let g:Powerline_symbols = 'unicode'

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
