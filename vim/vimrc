syntax on
"colorscheme murphy 

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
set shortmess=atI               " ???
set magic                       " For regular expressions turn magic on
set title                       " change the terminal's title
set history=1000                " history : how many lines of history VIM has to remember
set nobackup                    " do not keep a backup file
set noswapfile
set novisualbell                " turn off visual bell
set noerrorbells                " don't beep (set noeb)

set scrolloff=2                 " " movement keep 3? lines when scrolling
" ???
set visualbell t_vb=            " turn off error beep/flash
"set t_vb=
"set tm=500

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
"set smarttab                    " at the beginning of line and section?
set expandtab                   " expand tabs to spaces

" search
set hlsearch                    " highlight searches
set incsearch                   " do incremental searching, search as you type
set ignorecase                  " !!! ignore case when searching
set smartcase                   " no ignorecase if Uppercase char present

" encoding
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1 "?fencs"
set termencoding=utf-8
" ???"
set fileformats=unix,dos,mac
set formatoptions+=m
set formatoptions+=B

" select & complete
set mouse=a                      " use mouse anywher in buffer"
set selection=exclusive          " ???exclusive"
set selectmode=mouse,key

set completeopt=longest,menu            " coding complete with filetype check
set clipboard+=unnamed                  " share clipboard
set wildmenu                           " show a navigable menu for tab completion"
set wildmode=longest,list,full
set wildignore=*.o,*~,*.pyc,*.class
set linespace=0       " the line count to insert between words"

set list
set listchars=tab:»·,trail:·,nbsp:+

hi MyTabSpace guifg=darkgrey ctermfg=darkgrey
match MyTabSpace /\t\| /

" set mark column color
hi! link SignColumn   LineNr
hi! link ShowMarksHLl DiffAdd
hi! link ShowMarksHLu DiffChange
hi LineNr ctermfg=grey
hi CursorLineNr cterm=bold ctermfg=lightgreen

" status line
set laststatus=2   " Always show the status line - use 2 lines for the status bar
set cmdheight=1    " cmdline which under status line height, default = 1"

set statusline=
set statusline+=\%1*[%n] " buffer number
set statusline+=\ %<%.50F " file path maxlength=50
set statusline+=%=%2*\%y%m%r%h%w\ %* " [filetype] [show'+'ifmodified]
set statusline+=%3*\%{&ff}\[%{(&fenc==\"\")?&enc:&fenc}%* " encoding
set statusline+=%3*\%{(&bomb?\",BOM\":\"\")}]\ %* " encoding has BOM
set statusline+=%4*row:%l/%L\ col:%c\ %*
set statusline+=%5*\%3p%%\ %* " current line percent
set statusline+=%6*%{strftime(\"%H:%M\")}\ %*

"hi statusline ctermbg=darkgrey
hi User1 ctermfg=white ctermbg=darkgrey
hi User2 ctermfg=red ctermbg=darkgrey
hi User3 ctermfg=cyan ctermbg=darkgrey
hi User4 ctermfg=yellow ctermbg=darkgrey
hi User5 ctermfg=green ctermbg=darkgrey
hi User6 ctermfg=lightgrey ctermbg=darkgrey

" au=autocmd
"autocmd FileType python set tabstop=4 shiftwidth=4 expandtab
"augroup what
     "highlight show (need *.vim script)"
"    autocmd BufRead,BufNew *.md,*.mkd,*.markdown  set filetype=markdown.mkd
"    autocmd BufRead,BufNewFile *  setfiletype txt
"    autocmd InsertLeave * se nocul  " highlight line use light color
"    autocmd InsertEnter * se cul    " highlight line use light color too?
"augroup END
"
"augroup relative_numbser
"    autocmd!
"    autocmd InsertEnter * :set norelativenumber
"    autocmd InsertLeave * :set relativenumber
"augroup END

"set relativenumber

" others
set backspace=indent,eol,start  " make that backspace key work the way it should
set whichwrap+=<,>,h,l          " allow backspace and cursor crossi line border
set viminfo+=!      " save global variable
set report=0        "commands to tell user which line modified"
set fillchars=vert:\ ,stl:\ ,stlnc:\     " show blank between split window
"set background=dark

"set foldenable          " allow to fold 
"set foldmethod=manual   " fold manual
"set foldcolumn=0
"set foldlevel=1

set guioptions-=T  " hide tool bar
set guioptions-=m  " hide menu bar
set langmenu=zh_CN.UTF-8
set helplang=cn

" disable auto wrap and auto comments
set formatoptions-=cro

if !has('nvim')
    set ttymouse=xterm2
endif

" CTags
let Tlist_Auto_Open = 1             " open taglist as default"
let Tlist_Sort_Type = 'name'        " sort by name
let Tlist_Use_Right_Window = 1      " show taglist window at right
let Tlist_Compart_Format = 1        " compress way
let Tlist_File_Fold_Auto_Close = 0  " donnot close other files tags  
let Tlist_Enable_Fold_Column = 0    " donnot show folded tree
let Tlist_Ctags_Cmd = '/usr/bin/ctags'
let Tlist_Show_One_File = 1         " show current file only
let Tlist_Exit_OnlyWindow = 1       " exit vim if taglist window is the last window

" https://github.com/ryanpcmcquen/fix-vim-pasting
let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

imap <special> <expr> <Esc>[200~ XTermPasteBegin()
" Esc cancel highlight
nmap <Esc> :noh<CR>
nmap - ddkP
nmap + ddp
imap <C-d> <Esc>ddi
imap <C-z> <Esc>ui

function! XTermPasteBegin()
    set pastetoggle=<Esc>[201~
    set paste
    return ''
endfunction

" minibufexpl plugin
let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1

