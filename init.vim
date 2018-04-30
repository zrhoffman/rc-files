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


runtime! ftplugin/man.vim
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
"vimball
Plugin 'vim-scripts/Vimball'

"RLS, which is better than just racer
"Plugin 'autozimu/LanguageClient-neovim'
"autocompletion
Plugin 'valloric/YouCompleteMe'
Plugin 'roxma/nvim-completion-manager'
Plugin 'racer-rust/vim-racer'
Plugin 'roxma/nvim-cm-racer'
"linting
Plugin 'vim-syntastic/syntastic'
"debugging
"vimscript is more up-to-date (unless you find another repo)
"Plugin 'vim-scripts/Conque-GDB'
"Bundle 'dbgx/gdb.vim'
Bundle 'dbgx/lldb.nvim'

"let Vundle manage Vundle, required
Bundle 'gmarik/Vundle.vim'

"These are all one thing
Bundle 'Shougo/vimproc.vim'
Bundle 'Shougo/unite.vim'

"Project-wide find/replace
Bundle 'henrik/vim-qargs'
Bundle 'henrik/git-grep-vim'
call vundle#end()            " required

set rtp+=~/.vim/bundle/gdb.vim/plugin/gdb.vim
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
    "au FileType rust autocmd BufEnter * ConqueGdbExe rust-gdb
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

"neovim stuff
"because neovim has terrible colors
"It turns out peachpuff is the vim default one. Great.
colorscheme peachpuff
"because they made search yellow by default
hi Search term=standout ctermfg=4 ctermbg=7 guifg=DarkBlue guibg=LightGrey
