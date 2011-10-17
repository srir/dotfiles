set number
set nowrap
syntax enable
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set cindent
set autoindent " doesn't interfere with filetype indents, and is useful for text  
if has("autocmd")  
    " Enable file type detection and indentation  
    filetype plugin indent on  
    set nosmartindent  
endif 
au BufNewFile,BufRead *.c0 set filetype=c
au BufNewFile,BufRead *.h0 set filetype=h
colo molokai
map <Home> ^
imap <Home> <Esc>^i
set grepprg=grep\ -nH\ $*
let g:tex_flavor='latex'
inoremap [] []
inoremap () ()
inoremap {} {}
inoremap :: ::
inoremap == ==
