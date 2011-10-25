" set up autoloading
call pathogen#infect()
call pathogen#helptags()

" general editor view
set number
set nowrap
syntax enable
set visualbell t_vb=
set incsearch

" indentation
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent " doesn't interfere with filetype indents, and is useful for text  
if has("autocmd")  
    " Enable file type detection and indentation  
    filetype plugin indent on
    set nosmartindent  
endif 

" extra filetypes
au BufNewFile,BufRead *.c0 set filetype=c
au BufNewFile,BufRead *.h0 set filetype=h

" coloring
colo jellybeans
au Filetype *.tex colo molokai

" keymaps
map <Home> ^
imap <Home> <Esc>^i
set grepprg=grep\ -nH\ $*
let g:tex_flavor='latex'
