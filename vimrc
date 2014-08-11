set nocompatible
filetype off

" Vundle
set rtp+=~/.vim/bundle/Vundle.vim/

call vundle#begin()

Plugin 'gmarik/Vundle.vim'

" bundles
Plugin 'bling/vim-airline'
Plugin 'jeffkreeftmeijer/vim-numbertoggle'
Plugin 'altercation/vim-colors-solarized'

call vundle#end()

" general editor view
set number
set nowrap
syntax enable
set incsearch
set laststatus=2
set noshowmode

" colors
set background=light
colo solarized

" fonts
let g:airline_powerline_fonts = 1

" disable error bells
set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=

" indentation
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent " doesn't interfere with filetype indents, and is useful for text  
if has("autocmd")  
  " Enable file type detection and indentation  
  filetype plugin indent on
  set nosmartindent  
endif 

set autochdir

" immediate insert mode exit
if ! has('gui_running')
  set ttimeoutlen=10
  augroup FastEscape
    autocmd!
    au InsertEnter * set timeoutlen=0
    au InsertLeave * set timeoutlen=1000
  augroup END
endif
