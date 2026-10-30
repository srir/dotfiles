set nocompatible
filetype off

if ! has('gui_running')
  let g:loaded_youcompleteme = 1
endif

" Vundle
set rtp+=~/.vim/bundle/Vundle.vim/

call vundle#begin()

Plugin 'gmarik/Vundle.vim'

" bundles
Plugin 'bling/vim-airline'
Plugin 'jeffkreeftmeijer/vim-numbertoggle'
Plugin 'altercation/vim-colors-solarized'
Plugin 'chriskempson/base16-vim'
Plugin 'kien/ctrlp.vim'
Plugin 'pangloss/vim-javascript'
Plugin 'leafgarland/typescript-vim'
Plugin 'clausreinke/typescript-tools.vim'
Plugin 'Valloric/YouCompleteMe'

if !exists("g:ycm_semantic_triggers")
  let g:ycm_semantic_triggers = {}
endif
let g:ycm_semantic_triggers['typescript'] = ['.']

call vundle#end()

" general editor view
set number
set nowrap
syntax enable
set incsearch
set laststatus=2
set noshowmode
set nobackup
set noswapfile

" ctrlp
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'r'
let g:ctrlp_custom_ignore = '\v[\/](node_modules|_build)|(\.(swp|ico|git|svn))$'

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
  au BufRead,BufNewFile *.ts setlocal filetype=typescript
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
