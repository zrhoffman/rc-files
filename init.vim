set clipboard=unnamed,unnamedplus
set noswapfile
set nocompatible
filetype off

"fast escape key (though tmux.conf needs to be changed too)
set timeoutlen=1000 ttimeoutlen=0

"print the column number in the statusline
set statusline+=col:\ %c,

filetype plugin on

let &termencoding = &encoding
set encoding=utf-8 nobomb
syntax on
filetype plugin indent on
set number

" Added 12/10-2014 and it works in cygwinvim.bat now!
let &termencoding = &encoding
set nobackup

" http://stackoverflow.com/questions/1878974/redefine-tab-as-4-spaces
" size of a hard tabstop
set tabstop=4

" size of an "indent"
set shiftwidth=4

" a combination of spaces and tabs are used to simulate tab stops at a width
" other than the (hard)tabstop
set softtabstop=4
" make "tab" insert indents instead of tabs at the beginning of a line
set smarttab

" always uses spaces instead of tab characters
set expandtab

" font size
set guifont=Monospace\ 15

" Clipboard stays after exit
autocmd VimLeave * call system("xsel -ib", getreg('+'))

"Now I can always see the filename
set statusline+=%F
set laststatus=2

"neovim stuff
"because neovim has terrible colors
"It turns out peachpuff is the vim default one. Great.
colorscheme peachpuff
"because they made search yellow by default
hi Search term=standout ctermfg=4 ctermbg=7 guifg=DarkBlue guibg=LightGrey

runtime! ftplugin/man.vim
set rtp+=~/.vim/bundle/Vundle.vim
call plug#begin()
" PHP Language server
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'felixfbecker/php-language-server', {'do': 'composer install && composer run-script parse-stubs'} "If this doesn't work for some reason, you need to go into the php-language-server plugin folder and do a composer install
"
" Autocomplete
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

Plug 'autozimu/LanguageClient-neovim'
Plug 'roxma/LanguageServer-php-neovim', {'do': 'composer install && composer run-script parse-stubs'}

"vimball
Plug 'vim-scripts/Vimball'

"RLS, which is better than just racer
"Plugin 'autozimu/LanguageClient-neovim'
"autocompletion
Plug 'valloric/YouCompleteMe' "you have to go into the YouCompleteMe plugin folder and run install.py
Plug 'roxma/nvim-completion-manager'
Plug 'racer-rust/vim-racer'
Plug 'roxma/nvim-cm-racer'
"linting
Plug 'vim-syntastic/syntastic'
"debugging
Plug 'dbgx/lldb.nvim' "you need to run UpdateRemotePlugins after installing this for it to work

"These are all one thing
Plug 'Shougo/vimproc.vim'
Plug 'Shougo/unite.vim'

"Project-wide find/replace
Plug 'henrik/vim-qargs'
Plug 'henrik/git-grep-vim'

"Vim linting
Plug 'ynkdir/vim-vimlparser'
Plug 'syngan/vim-vimlint'
call plug#end()

"Everything after this point is plugin and language/filetype-specific
"configuration
"
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

nnoremap <c-]>  :tab split<cr>:LspDefinition<cr>
nnoremap K :LspHover<cr>

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

"Rust section begin
let g:racer_cmd = expand("~")."/.cargo/bin/racer"
let g:racer_experimental_completer = 1

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

au FileType rust nmap gd <Plug>(rust-def)
"au FileType rust nmap gs <Plug>(rust-def-split)
au FileType rust nmap gx <Plug>(rust-def-vertical)
"au FileType rust nmap <Leader>gd <Plug>(rust-doc)

"autoformat. relies on rustfmt-nightly/rustfmt-preview
let g:rustfmt_autosave = 1

nnoremap <silent><buffer> <Plug>(rust-def-tab)
        \ :tab split<CR>:call racer#GoToDefinition()<CR>
au FileType rust nmap gs <Plug>(rust-def-tab)

au FileType rust    nnoremap <Leader>g :LLsession new<CR>
"au FileType rust    nmap <M-b> <Plug>LLBreakSwitch
au FileType rust    nmap <S-F9> <Plug>LLBreakSwitch
au FileType rust    vmap <F2> <Plug>LLStdInSelected
au FileType rust    nnoremap <F4> :LLstdin<CR>
au FileType rust    nnoremap <F5> :w<CR>:LLmode debug<CR>
au FileType rust    nnoremap <S-F5> :LLmode code<CR>
au FileType rust    nnoremap <F8> :LL continue<CR>
au FileType rust    nnoremap <S-F8> :LL process interrupt<CR>
au FileType rust    nnoremap <F9> :LL print <C-R>=expand('<cword>')<CR>
au FileType rust    vnoremap <F9> :<C-U>LL print <C-R>=lldb#util#get_selection()<CR><CR>

"So I can build stuff
runtime! compiler/cargo.vim
"compiler cargo

if exists("g:loaded_syntastic_rust_cargo_checker")
    finish
endif
let g:loaded_syntastic_rust_cargo_checker = 1

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

let s:save_cpo = &cpo
set cpo&vim
let &cpo = s:save_cpo
unlet s:save_cpo

" https://github.com/rust-lang/rust.vim/pull/147
" this makes syntastic work with cargo
function! SyntaxCheckers_rust_cargo_GetLocList() dict
    let makeprg = self.makeprgBuild({
             \ 'args': 'build',
             \ 'fname': '' })

    " Old errorformat (before nightly 2016/08/10)
    let errorformat  =
        \ '%E%f:%l:%c: %\d%#:%\d%# %.%\{-}error:%.%\{-} %m,'   .
        \ '%W%f:%l:%c: %\d%#:%\d%# %.%\{-}warning:%.%\{-} %m,' .
        \ '%C%f:%l %m'

    " New errorformat (after nightly 2016/08/10)
    let errorformat  .=
        \ ',' .
        \ '%-G,' .
        \ '%-Gerror: aborting %.%#,' .
        \ '%-Gerror: Could not compile %.%#,' .
        \ '%Eerror: %m,' .
        \ '%Eerror[E%n]: %m,' .
        \ '%-Gwarning: the option `Z` is unstable %.%#,' .
        \ '%Wwarning: %m,' .
        \ '%Inote: %m,' .
        \ '%C %#--> %f:%l:%c'

    return SyntasticMake({
        \ 'makeprg': makeprg,
        \ 'errorformat': errorformat })
endfunction

let g:syntastic_rust_checkers = ['cargo']
let g:syntastic_rust_cargo_args = "build"

function! <SID>LoadCargo()
    if exists('g:load_cargo_ran')
        return
    endif
    let g:load_cargo_ran = 1
    call g:SyntasticRegistry.CreateAndRegisterChecker({ 'filetype': 'rust', 'name': 'cargo'})
endfunction
runtime! plugin/syntastic/*.vim

augroup CargoLoader
    au FileType rust autocmd BufEnter * call <SID>LoadCargo()
augroup end

"The RLS thing too
"augroup filetype_rust
"    autocmd!
"    autocmd BufReadPost *.rs setlocal filetype=rust
"augroup END

"Linting
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Rust section end
