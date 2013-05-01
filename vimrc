set nocompatible
filetype off

" Vundle
set rtp+=~/.vim/bundle/vundle/
set rtp+=~/.vim/bundle/powerline/powerline/bindings/vim/

call vundle#rc()

Bundle 'gmarik/vundle'

" bundles
Bundle 'mrtazz/molokai.vim'
Bundle 'nanotech/jellybeans.vim'
Bundle 'Lokaltog/powerline'
Bundle 'jeffkreeftmeijer/vim-numbertoggle'

" general editor view
set number
set nowrap
syntax enable
set incsearch
set laststatus=2

" colors
set background=dark
colo jellybeans

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
