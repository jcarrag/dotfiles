set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" better safe than sorry https://stackoverflow.com/a/5845583/4596773
set nocompatible

" install Plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'VundleVim/Vundle.vim'

Plug 'derekwyatt/vim-scala'
Plug 'ensime/ensime-vim', { 'do': ':UpdateRemotePlugins' }

Plug 'vim-scripts/paredit.vim'
Plug 'guns/vim-clojure-static'
Plug 'guns/vim-clojure-highlight'
Plug 'tpope/vim-fireplace'
Plug 'tpope/vim-classpath'
Plug 'tpope/vim-fugitive'
Plug 'terryma/vim-multiple-cursors'

Plug 'w0rp/ale'
Plug 'vim-airline/vim-airline'
Plug 'guns/vim-slamhound'

Plug 'mileszs/ack.vim'
call plug#end()

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

" use Ag with Ack
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
cnoreabbrev ag Ack!
cnoreabbrev aG Ack!
cnoreabbrev Ag Ack!
cnoreabbrev AG Ack!
