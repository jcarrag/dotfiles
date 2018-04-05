" better safe than sorry https://stackoverflow.com/a/5845583/4596773
set nocompatible

" don't detect filetype for Vundle
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

Plugin 'derekwyatt/vim-scala'

Plugin 'vim-scripts/paredit.vim'
Plugin 'guns/vim-clojure-static'
Plugin 'guns/vim-clojure-highlight'
Plugin 'tpope/vim-fireplace'
Plugin 'tpope/vim-classpath'
Plugin 'tpope/vim-fugitive'
Plugin 'terryma/vim-multiple-cursors'

Plugin 'w0rp/ale'
Plugin 'vim-airline/vim-airline'
Plugin 'guns/vim-slamhound'
call vundle#end()

" detect filetypes again
filetype plugin indent on

" syntax highlighting
syntax on

" enable mouse highlighting with Mouse Reporting
set mouse=a

" rebind <leader>
let mapleader=","

" bind fd to <Esc> non-recursively in insert mode
inoremap fd <Esc>

" eagerly attempty vim-clojure-highlight
autocmd BufRead *.clj try | silent! Require | catch /^Fireplace/ | endtry

" show line numbers
set number

" Highlight all occurrences of a search
set hlsearch

" remap window navigation non-recursively in normal mode
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set splitbelow
set splitright

" integrate ale with airline
let g:airline#extensions#ale#enabled = 1

" stop vim from creating automatic backups
set noswapfile
set nobackup
set nowb

" jk instead of arrows
" http://stackoverflow.com/questions/4016649/vim-word-completion-navigating-with-j-and-k
inoremap <expr> j pumvisible() ? "\<C-N>" : "j"
inoremap <expr> k pumvisible() ? "\<C-P>" : "k"

" Shift+Tab unindents a line
imap <S-Tab> <Esc><<i
nmap <S-tab> <<
