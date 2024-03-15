set encoding=utf-8
scriptencoding utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
set termencoding=utf-8

if has('syntax')
    syntax on
endif

set t_Co=256

let vim_install_path=$VIMRUNTIME
let theme_file=vim_install_path.'/colors/habamax.vim'
if filereadable(theme_file)
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

set scrolloff=7                 " movement keep 3 lines when scrolling
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
set cmdheight=1    " cmdline which under status line height, default = 1

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
    " --- open file at the last edit line
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
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

let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

" keyborad bind
let mapleader = "\<space>"

" ------- normal noremap -------
nnoremap <space>s :w<CR>
nnoremap <space>q :wq<CR>
nnoremap <space>Q :wqa<CR>
nnoremap <space>e :q!<CR>
nnoremap <C-a> ggVG
" nnoremap <space>2 @=((foldclosed(line('.')) < 0) ? 'zc' : 'zo')<CR>

" cancel highlight search word
nnoremap <silent> <space><bs> :noh<CR>
" goto next search result and focus on this line
nnoremap n nzz
" goto previous search result and focus on this line
nnoremap N Nzz

" Yank text to EOL
nnoremap <silent> Y y$
" Delete text to EOL
nnoremap <silent> D d$

" move current line down
nnoremap = :m +1<CR>
" move current line up
nnoremap - :m -2<CR>

nnoremap tn :tabnew<CR>
nnoremap tk :tabnext<CR>
nnoremap tj :tabprevious<CR>
nnoremap to :tabonly<CR>
nnoremap tc :tabclose<CR>

nnoremap sh :setlocal nosplitright<CR>:vsplit<CR>
nnoremap sl :setlocal splitright<CR>:vsplit<CR>
nnoremap sk :setlocal nosplitbelow<CR>:split<CR>
nnoremap sj :setlocal splitbelow<CR>:split<CR>

nnoremap <C-h> :wincmd h<CR>
nnoremap <C-l> :wincmd l<CR>
nnoremap <C-j> :wincmd j<CR>
nnoremap <C-k> :wincmd k<CR>

nnoremap <leader>[ :vertical resize -5<CR>
nnoremap <leader>] :vertical resize +5<CR>
nnoremap <leader>; :resize -2<CR>
nnoremap <leader>' :resize +2<CR>

nnoremap <leader>fe :vsp /etc/vimrc<CR>
nnoremap <leader>fr :call SourceAllVimRc()<CR>
" search for word equal to each
nnoremap <leader>fd /\(\<\w\+\>\)\_s*\1
" trim EOL trailing space
nnoremap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>
" Enter break line
nnoremap <leader><CR> i<CR><Esc>k$
" Move to a new line

" ------- insert noremap -------
inoremap <C-d> <Esc>ddi
inoremap <C-z> <Esc>ui
inoremap <C-u> <C-G>u<C-U>
inoremap <C-b> <C-Left>
inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

" ------- visual noremap -------
let t_ExistOutput = system('command -v xclip')
if strlen(t_ExistOutput) > 0
    vnoremap <C-c> :w !xclip -selection clipboard<CR>
endif

" ------- custom function -------
function! XTermPasteBegin()
    set pastetoggle=<Esc>[201~
    set paste
    return ''
endfunction

if !exists("*SourceAllVimRc")
    function! SourceAllVimRc()
        let finls = "sourced files: "
        for file in ['/etc/vimrc', '/etc/vim/vimrc', $MYVIMRC]
            if filereadable(expand(file))
                exec 'source' file
                let finls = finls.' '.file
            endif
        endfor
        exec 'noh'
        echohl finls
    endfunction
endif
