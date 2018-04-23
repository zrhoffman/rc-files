if filereadable("composer.json")
    "For phpcomplete-extended
    autocmd  FileType  php setlocal omnifunc=phpcomplete_extended#CompletePHP
    let g:SuperTabDefaultCompletionType = "<c-x><c-o>"
    "My setup
    let g:phpcomplete_index_composer_command = "composer"
    let g:phpcomplete_extended_cache_disable = 1
    "Bundle 'm2mdas/phpcomplete-extended'
    "Bundle 'm2mdas/phpcomplete-extended-symfony'
    echo system("mv ~/.vim/unused/* ~/.vim/bundle")
    echo system("mv ~/.vim/bundle/phpcomplete.vim ~/.vim/unused")
else
    "For phpcomplete
    let g:phpcomplete_parse_docblock_comments = 1
    let g:phpcomplete_search_tags_for_variables = 1
    Bundle 'shawncplus/phpcomplete.vim'
    echo system("mv ~/.vim/unused/* ~/.vim/bundle")
    echo system("mv ~/.vim/bundle/phpcomplete-extended* ~/.vim/unused")
endif

"Generate PHP documentation
Bundle 'tobyS/vmustache'
Bundle 'SirVer/ultisnips'
Bundle 'tobyS/pdv'

"Service and routing autocomplete for Symfony
"Bundle 'docteurklein/vim-symfony'
Bundle 'willdurand/vim-symfony'
Bundle 'squizlabs/PHP_CodeSniffer'
Bundle "joonty/vdebug"
vundle#end
" PHP documenter script bound to Control-P
let g:pdv_template_direrrorformat  = $HOME ."/.vim/bundle/pdv/templates_snip"
"autocmd FileType php inoremap <C-p> <ESC>:call pdv#DocumentCurrentLine()<CR>i
"autocmd FileType php nnoremap <C-p> :call pdv#DocumentCurrentLine()<CR>
"autocmd FileType php vnoremap <C-p> :call pdv#DocumentCurrentLine()<CR>\ '%E%f:%l:%c: %\d%#:%\d%# %.%\{-}error:%.%\{-} %m,'   .
nnoremap <buffer> <C-p> :call pdv#DocumentWithSnip()<CR>
"nnoremap <buffer> <C-p> :call pdv#DocumentCurrentLine()<CR>
