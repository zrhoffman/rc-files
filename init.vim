set clipboard=unnamed,unnamedplus
set noswapfile nobackup
set number
syntax on

" mozilla standard
" no longer official, as mozilla uses
" https://google.github.io/styleguide/cppguide.html now
"set ts=8 sts=2 et sw=2 tw=80

"wrap lines at 80 characters
set textwidth=80

" https://stackoverflow.com/questions/1878974
set tabstop=4 softtabstop=4 expandtab shiftwidth=4 smarttab

"fast escape key (though tmux.conf needs to be changed too)
set timeoutlen=1000 ttimeoutlen=0

"print the column number in the statusline
set statusline+=col:\ %c,

"Now I can always see the filename
set statusline+=%F
set laststatus=2

" cygwin compatibility
let &termencoding = &encoding
set encoding=utf-8 nobomb
" not necessary in neovim
set nocompatible
filetype plugin indent on

" Clipboard stays after exit
autocmd VimLeave * call system("xsel -ib", getreg('+'))

runtime! ftplugin/man.vim
call plug#begin()
"C++
Plug 'huawenyu/neogdb.vim'

"Bash
Plug 'mads-hartmann/bash-language-server'

"pdv dependencies
Plug 'SirVer/ultisnips'
Plug 'tobyS/vmustache'
"PHP Documentor for Vim
Plug 'tobyS/pdv'

"Blade template syntax highlighting
Plug 'jwalton512/vim-blade'

" PHP Language server
"Plug 'prabirshrestha/async.vim'
Plug 'felixfbecker/php-language-server', {'do': 'composer install && composer run-script parse-stubs'} "If this doesn't work for some reason, you need to go into the php-language-server plugin folder and do a composer install
"
"LanguageClient-neovim' is neovim-only
Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }
Plug 'junegunn/fzf'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

"Extract vimballs from www.vim.org
Plug 'vim-scripts/Vimball'

"RLS, which is better than just racer
"Plugin 'autozimu/LanguageClient-neovim'
"
"autocompletion
"Plug 'valloric/YouCompleteMe' "you have to go into the YouCompleteMe plugin folder and run python3 install.py --rust-completer --go-completer --clang-completer
Plug 'ncm2/ncm2' " (neovim-only, successor to roxma/nvim-completion-manager)
Plug 'roxma/nvim-cm-racer' "(neovim-only) requires ncm2/ncm2
Plug 'racer-rust/vim-racer'

"linting
Plug 'vim-syntastic/syntastic'
Plug 'rust-lang/rust.vim'

"debugging
Plug 'dbgx/lldb.nvim' "(neovim-only, unmaintained as of 2018-03-11) you need to run UpdateRemotePlugins after installing this for it to work
Plug 'WolfgangMehner/bash-support'

"TOML syntax hightlighting
Plug 'cespare/vim-toml'

"These are all one thing
Plug 'Shougo/vimproc.vim'
Plug 'Shougo/unite.vim'

"Vimscript linting
Plug 'ynkdir/vim-vimlparser'
Plug 'syngan/vim-vimlint'

"Theme
Plug 'NLKNguyen/papercolor-theme'
call plug#end()

"neovim stuff
"because neovim has terrible colors
set t_Co=256   " This is may or may not needed.
set background=light
colorscheme PaperColor

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

autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif
"autocmd FileType php setlocal omnifunc=LanguageClient#complete
"au FileType php setlocal completefunc=LanguageClient#complete

au FileType php let g:LanguageClient_serverCommands = {
    \ 'php': ['php', expand("~") . '/.config/nvim/plugged/php-language-server/bin/php-language-server.php'],
    \ }
au FileType php let g:LanguageClient_autoStart = 1
au FileType php nnoremap <F5> :call LanguageClient_contextMenu()<CR>

"PHP section end

"JavaScript section begin
"let g:syntastic_javascript_checkers = ['eslint']
"let g:syntastic_javascript_eslint_exec = 'eslint_d'
"Javascript section end

"Rust section begin
au FileType rust let g:racer_cmd = expand("~") . "/.cargo/bin/racer"
au FileType rust let g:racer_experimental_completer = 1

"RLS stuff
au FileType rust let g:LanguageClient_serverCommands = {
    \ 'rust': ['rustup', 'run', 'nightly', 'rls'],
    \ }

au FileType rust nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
au FileType rust nmap gd :tab split<CR> :call LanguageClient_textDocument_definition()<CR>
au FileType rust nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>

au FileType php nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
au FileType php nnoremap <silent> gd :tab split<CR>:call LanguageClient_textDocument_definition()<CR>
au FileType php nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>

" Also for RLS
" Always draw sign column. Prevent buffer moving when adding/deleting sign.
"set signcolumn=yes

let g:mapleader = "\\"
let g:echodoc_enable_at_startup = 1
set completeopt+=noinsert
"RLS autocomplete
au FileType rust let g:LanguageClient_autoStart = 1
au FileType rust set completefunc=LanguageClient#complete

"autoformat. relies on rustfmt-nightly/rustfmt-preview
au FileType rust let g:rustfmt_autosave = 1

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

au FileType rust    nmap        <F8>  <Plug>LLBreakSwitch
au FileType rust    vmap        <F2>    <Plug>LLStdInSelected
au FileType rust    nnoremap    <F4>    :LLstdin<CR>
au FileType rust    nnoremap    <F5>    :call StartLLDBSession()<CR>
au FileType rust    nnoremap    <S-F5>  :LLmode code<CR>
au FileType rust    nnoremap    <F9>    :LL continue<CR>
au FileType rust    nnoremap    <S-F9>  :LL process interrupt<CR>
au FileType rust    nnoremap    <S-F8>    :LL print <C-R>=expand('<cword>')<CR>
au FileType rust    vnoremap    <S-F8>    :<C-U>LL print <C-R>=lldb#util#get_selection()<CR><CR>

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


let g:pdv_template_dir = expand('~')."/.config/nvim/plugged/pdv/templates_snip"
nnoremap <buffer> <C-p> :call pdv#DocumentWithSnip()<CR>

"C++
let g:neobugger_leader = ';'
function! GdbCommmand(command)
    call neobugger#Handle('current', 'Send', a:command)
endfunction
