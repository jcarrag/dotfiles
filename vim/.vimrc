" better safe than sorry https://stackoverflow.com/a/5845583/4596773
set nocompatible

" install Plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'VundleVim/Vundle.vim'

" Misc
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'majutsushi/tagbar'
Plug 'scrooloose/nerdtree'
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'sheerun/vim-polyglot'
Plug 'chrisbra/Colorizer'
Plug 'terryma/vim-multiple-cursors'
Plug 'w0rp/ale'
Plug 'vim-airline/vim-airline'
Plug 'guns/vim-slamhound'
Plug 'mileszs/ack.vim'

" Git
Plug 'tpope/vim-fugitive'

" Scala
Plug 'derekwyatt/vim-scala'
Plug 'ensime/ensime-vim'

" Clojure
Plug 'vim-scripts/paredit.vim'
Plug 'guns/vim-clojure-static'
Plug 'guns/vim-clojure-highlight'
Plug 'tpope/vim-fireplace'
Plug 'tpope/vim-classpath'

" Aesthetics - Main
Plug 'dracula/vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'

call plug#end()

""" Colouring

" colourscheme
set encoding=utf8
syntax on
color dracula
"highlight Pmenu guibg=white guifg=black gui=bold
"highlight Comment gui=bold
"highlight Normal gui=none
"highlight NonText guibg=noned=light

" Opaque Background (Comment out to use terminal's profile)
"set termguicolors

""" Vim config

" osx clipboard
set clipboard=unnamed

" enable mouse highlighting with Mouse Reporting
set mouse=a

" show line numbers
set number

" Highlight all occurrences of a search
set hlsearch

" stop vim from creating automatic backups
"set noswapfile
"set nobackup
"set nowb

""" Bindings

" rebind <leader>
let maplocalleader=","

" remap window navigation non-recursively in normal mode
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
set splitbelow
set splitright

" jk instead of arrows
" http://stackoverflow.com/questions/4016649/vim-word-completion-navigating-with-j-and-k
inoremap <expr> j pumvisible() ? "\<C-N>" : "j"
inoremap <expr> k pumvisible() ? "\<C-P>" : "k"

" Shift+Tab unindents a line
imap <S-Tab> <Esc><<i
nmap <S-tab> <<

" bind fd to <Esc> non-recursively in insert mode
inoremap fd <Esc>

""" Plugin config

" Ensime
au FileType scala nnoremap <localleader>df :EnDeclaration<CR>

" NERDTree
let NERDTreeShowHidden=1
let g:NERDTreeDirArrowExpandable = '↠'
let g:NERDTreeDirArrowCollapsible = '↡'

" Airline
let g:airline_powerline_fonts = 1
let g:airline_section_z = ' %{strftime("%-I:%M %p")}'
let g:airline_section_warning = ''

" Deoplete
let g:deoplete#enable_at_startup = 1
" Disable documentation window
set completeopt-=preview
" Let <Tab> also do completion
inoremap <silent><expr> <Tab>
\ pumvisible() ? "\<C-n>" :
\ deoplete#mappings#manual_complete()

" fzf-vim
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit' }
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'Type'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Character'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

" vim-fireplace
autocmd BufRead *.clj try | silent! Require | catch /^Fireplace/ | endtry

" autocomplete
let g:deoplete#enable_at_startup = 1

" integrate ale with airline
let g:airline#extensions#ale#enabled = 1

" use Ag with Ack
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
cnoreabbrev ag Ack!
cnoreabbrev aG Ack!
cnoreabbrev Ag Ack!
cnoreabbrev AG Ack!

