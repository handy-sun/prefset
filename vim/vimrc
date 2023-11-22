set encoding=utf-8
scriptencoding utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
set termencoding=utf-8

if has('syntax')
    syntax on
endif

if version >= 900
    colorscheme habamax
endif

" filetype
filetype on
filetype plugin on              " Enable filetype plugins
filetype indent on              " load specific type indent file

" base
set nocompatible                " don't bother with vi compatibility
set autoread                    " reload files when changed on disk
set autowrite
set gdefault
set confirm                     " processing ont save or read-only file, pop confirm
set shortmess=aTI
set magic                       " For regular expressions turn magic on
set title                       " change the terminal's title
set history=1000                " history : how many lines of history VIM has to remember
set nobackup                    " do not keep a backup file
set noswapfile
" set novisualbell                " turn off visual bell
set errorbells

set scrolloff=2                 " movement keep 3 lines when scrolling
set visualbell t_vb=

" show
""==set nu
set number                      " show line numbers
set ruler                       " show the current row and column
set showcmd                     " display incomplete commands
"set nowrap                      " auto linefeed
set showmode                    " display current modes
set showmatch                   " jump to matches when entering parentheses
set matchtime=1                 " tenths of a second to show the matching parenthesis
" show location
"set cursorcolumn                " highlight the whole column
set cursorline
set splitright
set splitbelow
set relativenumber
set background=dark

" indent
set autoindent
set cindent
set smartindent                 " ??? only for C language
set shiftround
set shiftwidth=4
" tab
set tabstop=4                   " tab width
set softtabstop=4                " insert mode tab and backspace use 4 spaces
"set noexpandtab                 " donnot use space relace tab
set smarttab                    " at the beginning of line and section?
set expandtab                   " expand tabs to spaces

" search
set hlsearch                    " highlight searches
set incsearch                   " do incremental searching, search as you type
set ignorecase                  " !!! ignore case when searching
set smartcase                   " no ignorecase if Uppercase char present
set infercase

set fileformats=unix,dos,mac

" select & complete
set mouse=a                      " use mouse anywher in buffer"
set selection=exclusive          " ???exclusive"
set selectmode=mouse,key

set completeopt=longest,menu            " coding complete with filetype check
set clipboard+=unnamed                  " share clipboard
set wildmenu                            " show a navigable menu for tab completion"
set wildmode=longest,list,full
"set wildignore=*.o,*~,*.pyc,*.class
set wildignore=.git,.hg,.svn,*.pyc,*.o,*.out,*.jpg,*.jpeg,*.png,*.gif,*.zip,**/tmp/**,*.DS_Store,**/node_modules/**,**/bower_modules/**
set wildignorecase

set list
set listchars=tab:»·,trail:·,nbsp:+

hi MyTabSpace ctermfg=darkgrey
match MyTabSpace /\t\| /

" set mark column color
hi! link SignColumn   LineNr
hi! link ShowMarksHLl DiffAdd
hi! link ShowMarksHLu DiffChange
hi Search cterm=bold ctermbg=darkyellow
"hi CursorLine ctermbg=black
hi LineNr ctermfg=darkgrey
hi CursorLineNr term=reverse cterm=bold ctermfg=lightgreen

" status line
set laststatus=2   " Always show the status line - use 2 lines for the status bar
set cmdheight=1    " cmdline which under status line height, default = 1"

set statusline=
set statusline+=\%7*[%n]                                   " buffer number
set statusline+=\ %8*%<%.50F                               " file path maxlength=50
set statusline+=%=\ %1*\%y%m%r%h%w\ %*                     " [filetype] [show'+'ifmodified]
set statusline+=%5*\%{&ff}\[%{(&fenc==\"\")?&enc:&fenc}%*  " encoding
set statusline+=%5*\%{(&bomb?\",BOM\":\"\")}]\ %*          " encoding has BOM
set statusline+=%3*row:%l/%L\ col:%c\ %*                   " curRow/totalRow, curColumn
set statusline+=%4*\%3p%%\ %*                              " current line percent
set statusline+=%9*%{strftime(\"%H:%M\")}\ %*

"hi statusline ctermbg=darkgrey
hi User1 ctermfg=red ctermbg=darkgrey
hi User2 ctermfg=brown ctermbg=darkgrey
hi User3 ctermfg=yellow ctermbg=darkgrey
hi User4 ctermfg=green ctermbg=darkgrey
hi User5 ctermfg=cyan ctermbg=darkgrey
hi User6 ctermfg=blue ctermbg=darkgrey
hi User7 ctermfg=magenta ctermbg=darkgrey
hi User8 ctermfg=white ctermbg=darkgrey
hi User9 ctermfg=lightgrey ctermbg=darkgrey

if has('autocmd')
augroup vimrcEx
    au FileType python set tabstop=4 shiftwidth=4 expandtab
    "au BufRead,BufNew *.md,*.mkd,*.markdown  set filetype=markdown.mkd
    "au BufRead,BufNewFile *  setfiletype txt
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif  " open file at the last edit line
augroup END
endif

" others
set backspace=indent,eol,start  " make that backspace key work the way it should
set whichwrap+=<,>,h,l          " allow backspace and cursor crossline border
set viminfo+=!      " save global variable
set report=0        " commands to tell user which line modified"
set fillchars=vert:\ ,stl:\ ,stlnc:\     " show blank between split window

set foldenable
set foldlevelstart=99
"set foldmethod=manual   " fold manual
"set foldcolumn=0
"set foldlevel=1

set langmenu=zh_CN.UTF-8
set helplang=en

" disable auto wrap and auto comments
set formatoptions-=co
set formatoptions+=mM


" https://github.com/ryanpcmcquen/fix-vim-pasting
" let &t_SI .= "\<Esc>[?2004h"
" let &t_EI .= "\<Esc>[?2004l"
" let &t_SI = "\<Esc>]50;CursorShape=1\x7"
" let &t_SR = "\<Esc>]50;CursorShape=2\x7"
" let &t_EI = "\<Esc>]50;CursorShape=0\x7"

" keyborad bind
let mapleader = "\<space>"

map <C-s> <Cmd>:w<CR>
map <C-q> <Cmd>:wq<CR>
map <C-a> ggVG

" Esc cancel highlight search word
nmap <Esc> <Cmd>nohlsearch<CR>
nmap Q <Cmd>wqa<CR>
"move this line down
nmap = <Cmd>move +1<CR>
"move this line up
nmap - <Cmd>move -1<CR>

nmap tn <Cmd>tabnew<CR>
nmap tk <Cmd>tabnext<CR>
nmap tj <Cmd>tabprevious<CR>
nmap to <Cmd>tabonly<CR>
nmap tc <Cmd>tabclose<CR>

nmap sh <Cmd>setlocal nosplitright<CR>:vsplit<CR>
nmap sl <Cmd>setlocal splitright<CR>:vsplit<CR>
nmap sk <Cmd>setlocal nosplitbelow<CR>:split<CR>
nmap sj <Cmd>setlocal splitbelow<CR>:split<CR>

nmap <C-h> <Cmd>wincmd h<CR>
nmap <C-l> <Cmd>wincmd l<CR>
nmap <C-j> <Cmd>wincmd j<CR>
nmap <C-k> <Cmd>wincmd k<CR>

nmap <leader>[  <Cmd>vertical resize -5<CR>
nmap <leader>]  <Cmd>vertical resize +5<CR>
nmap <leader>;  <Cmd>resize -2<CR>
nmap <leader>'  <Cmd>resize +2<CR>

nmap <leader>fe <Cmd>vsp /etc/vimrc<CR>
nmap <leader>fr <Cmd>source /etc/vimrc<CR><Cmd>source $MYVIMRC<CR>
" search for word equal to each
nmap <leader>fd /\(\<\w\+\>\)\_s*\1
" trim EOL trailing space
nmap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>
" Enter break line
nmap <leader><CR> i<CR><Esc>k$


""INSERT mode
"imap <C-s> <Esc>:w<CR>
"imap <C-q> <Esc>:wq<CR>

" delete one line
imap <C-d> <Esc>ddi
" undo
imap <C-z> <Esc>ui

imap <C-u> <C-G>u<C-U>
imap <C-b> <C-Left>
imap <special> <expr> <Esc>[200~ XTermPasteBegin()

""VISUAL mode
vmap J :m '>+1<CR>gv=gv
vmap K :m '<-2<CR>gv=gv
vmap < <gv
vmap > >gv

function! XTermPasteBegin()
    set pastetoggle=<Esc>[201~
    set paste
    return ''
endfunction

