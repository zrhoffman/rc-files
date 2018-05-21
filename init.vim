set clipboard=unnamed,unnamedplus
set noswapfile
set nocompatible

"fast escape key (though tmux.conf needs to be changed too)
set timeoutlen=1000 ttimeoutlen=0

"print the column number in the statusline
set statusline+=col:\ %c,

"Now I can always see the filename
set statusline+=%F
set laststatus=2

let &termencoding = &encoding
set encoding=utf-8 nobomb
syntax on
filetype plugin indent on
set number

" Added 12/10-2014 and it works in cygwinvim.bat now!
let &termencoding = &encoding
set nobackup

" https://stackoverflow.com/questions/1878974
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab

" font size
set guifont=Monospace\ 15

" Clipboard stays after exit
autocmd VimLeave * call system("xsel -ib", getreg('+'))

"neovim stuff
"because neovim has terrible colors
"It turns out peachpuff is the vim default one. Great.
colorscheme peachpuff
"because they made search yellow by default
hi Search term=standout ctermfg=4 ctermbg=7 guifg=DarkBlue guibg=LightGrey

runtime! ftplugin/man.vim
call plug#begin()
" PHP Language server
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'felixfbecker/php-language-server', {'do': 'composer install && composer run-script parse-stubs'} "If this doesn't work for some reason, you need to go into the php-language-server plugin folder and do a composer install
"
"Autocomplete
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

Plug 'autozimu/LanguageClient-neovim' "(neovim-only)
Plug 'roxma/LanguageServer-php-neovim', {'do': 'composer install && composer run-script parse-stubs'} "(neovim-only)

"Extract vimballs from www.vim.org
Plug 'vim-scripts/Vimball'

"RLS, which is better than just racer
"Plugin 'autozimu/LanguageClient-neovim'
"autocompletion
Plug 'valloric/YouCompleteMe' "you have to go into the YouCompleteMe plugin folder and run install.py --rust-completer
Plug 'roxma/nvim-completion-manager' " (neovim-only, unmaintained as of 2018-04-18)
Plug 'roxma/nvim-cm-racer' "(neovim-only) requires nvim-completion-manager
Plug 'racer-rust/vim-racer'
"linting
Plug 'vim-syntastic/syntastic'
Plug 'rust-lang/rust.vim'
"debugging
Plug 'dbgx/lldb.nvim' "(neovim-only, unmaintained as of 2018-03-11) you need to run UpdateRemotePlugins after installing this for it to work

"These are all one thing
Plug 'Shougo/vimproc.vim'
Plug 'Shougo/unite.vim'

"Project-wide find/replace
Plug 'henrik/vim-qargs'
Plug 'henrik/git-grep-vim'

"Vimscript linting
Plug 'ynkdir/vim-vimlparser'
Plug 'syngan/vim-vimlint'
call plug#end()

"Everything after this point is plugin and language/filetype-specific
"configuration

"PHP section start
" PLUGIN: vim-lsp
" Register server
" This thing is magic, I got it from https://github.com/prabirshrestha/vim-lsp/issues/32#issuecomment-325218962
function GetPLSPath()
    let composer_path = lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(),'composer.json')
    if exists(composer_path)
        let return_path = composer_path
    else
        let return_path = system('git rev-parse --show-toplevel')
    endif
    return return_path
endfunction

au User lsp_setup call lsp#register_server({
    \ 'name': 'php-language-server',
    \ 'cmd': {server_info->['php', expand('~/.config/nvim/plugged/php-language-server/bin/php-language-server.php')]},
    \ 'root_uri':{server_info->lsp#utils#path_to_uri(GetPLSPath()[:-2])},
    \ 'whitelist': ['php'],
    \ })

nnoremap <c-]>  :tab split<CR>:LspDefinition<CR>
nnoremap K :LspHover<CR>

let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('~/vim-lsp.log')

" for asyncomplete.vim log
let g:asyncomplete_auto_popup=1
let g:asyncomplete_remove_duplicates=1
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif
autocmd FileType php setlocal omnifunc=lsp#complete
let g:asyncomplete_log_file = expand('~/asyncomplete.log')

imap <C-Space> <Plug>(asyncomplete_force_refresh)
imap <Nul> <Plug>(asyncomplete_force_refresh)
"PHP section end

"Rust section begin
au FileType rust let g:racer_cmd = expand("~")."/.cargo/bin/racer"
au FileType rust let g:racer_experimental_completer = 1

"RLS stuff
"au FileType rust let g:LanguageClient_serverCommands = {
"    \ 'rust': ['rustup', 'run', 'nightly', 'rls'],
"    \ }
"au FileType rust nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
"au FileType rust nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
"au FileType rust nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>

" Also for RLS
" Always draw sign column. Prevent buffer moving when adding/deleting sign.
"set signcolumn=yes

let g:mapleader = "\\"
let g:echodoc_enable_at_startup = 1
set completeopt+=noinsert
"RLS autocomplete
"set completefunc=LanguageClient#complete

"autoformat. relies on rustfmt-nightly/rustfmt-preview
au FileType rust let g:rustfmt_autosave = 1

au FileType rust nmap gd <Plug>(rust-doc)
au FileType rust nnoremap <silent><buffer> <Plug>(rust-def-tab)
        \ :tab split<CR>:call racer#GoToDefinition()<CR>
au FileType rust nmap gs <Plug>(rust-def-tab)

function! StartLLDBSession()
    if !exists("g:session_created")
        let g:session_created = 1
        LLsession new
        "Automates starting the LLDB session.
        "The lldb.vim guy decided to call lldb#session#new() asynchronously from
        "python, so the timing is a crapshoot here
        let i = 0
        while i < 100
            let i = i + 1
            call feedkeys("\<CR>")
        endwhile
        sleep 1m
    endif
    call LLDebug()
    call LLClearStartingBreakpoint()
endfunction

function! LLDebug()
    write
    call lldb#remote#__notify("mode", "debug")
    if !exists("g:debugged_before")
        let g:debugged_before = 1
        let i = 0
        while i < 100
            let i = i + 1
            call feedkeys("\<CR>")
        endwhile
        "If this does not automate launching the target, make it sleep longer
        sleep 1000m
    endif
endfunction

function! LLClearStartingBreakpoint()
    if exists("g:starting_breakpoint_cleared")
        return
    endif
    let g:starting_breakpoint_cleared = 1
    normal gg
    call search("^fn main(")
    normal j
    call lldb#remote#__notify("breakswitch", bufnr("%"), getcurpos()[1])
    LL continue
endfunction

au FileType rust    nmap        <S-F9>  <Plug>LLBreakSwitch
au FileType rust    vmap        <F2>    <Plug>LLStdInSelected
au FileType rust    nnoremap    <F4>    :LLstdin<CR>
au FileType rust    nnoremap    <F5>    :call StartLLDBSession()<CR>
au FileType rust    nnoremap    <S-F5>  :LLmode code<CR>
au FileType rust    nnoremap    <F8>    :LL continue<CR>
au FileType rust    nnoremap    <S-F8>  :LL process interrupt<CR>
au FileType rust    nnoremap    <F9>    :LL print <C-R>=expand('<cword>')<CR>
au FileType rust    vnoremap    <F9>    :<C-U>LL print <C-R>=lldb#util#get_selection()<CR><CR>

function! <SID>LoadCargo()
    "In rust-lang/rust.vim
    runtime! syntax_checkers/rust/cargo.vim
    "So I can build stuff
    runtime! compiler/cargo.vim
    let g:syntastic_rust_checkers = ['cargo']
    let g:syntastic_rust_cargo_args = "build"
endfunction

au FileType rust call <SID>LoadCargo()

"The RLS thing too
"augroup filetype_rust
"    autocmd!
"    autocmd BufReadPost *.rs setlocal filetype=rust
"augroup END
"Rust section end

"Linting
runtime! plugin/syntastic/*.vim

" Syntastic syntax checkers:
" Ansible       ansible-lint        pacman
" CSS           CSSLint             AUR
" Dockerfile    dockerfile_lint     lol npm
" HTML          tidy                pacman
" JS            jshint              lol npm
" JSON          jsonlint            npm + fiddling
" Markdown      mdl                 gem
" shell         ShellCheck          AUR
" PHP           phpmd               composer
" Vim           vimlint/vimlparser  vundle

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
