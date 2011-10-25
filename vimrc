call pathogen#infect()
call pathogen#helptags()
set number
set nowrap
syntax enable
set incsearch
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set cindent
set autoindent " doesn't interfere with filetype indents, and is useful for text  
if has("autocmd")  
    " Enable file type detection and indentation  
    filetype plugin on
    filetype indent on
    set nosmartindent  
endif 
au BufNewFile,BufRead *.c0 set filetype=c
au BufNewFile,BufRead *.h0 set filetype=h
colo vividchalk
map <Home> ^
imap <Home> <Esc>^i
set grepprg=grep\ -nH\ $*
let g:tex_flavor='latex'
let delimitMate_expand_cr=1
