" Vim filetype plugin
" Language: Latte (Nette templating engine)
" Reuses the HTML filetype settings, switches comments to {* ... *} and adds
" Latte tag pairs to matchit's % ({if} -> {elseif} -> {else} -> {/if}, ...).

if exists('b:did_ftplugin')
  finish
endif

runtime! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
let b:did_ftplugin = 1

setlocal commentstring={*\ %s\ *}

" {if}/{foreach}/... share {else}, so they are one group; with proper nesting
" that still pairs the right tags. The other paired tags match by name.
let s:latte_match_words =
      \ '{\%(if\|ifset\|ifchanged\|foreach\|for\|while\)\>'
      \ . ':{\%(elseif\|elseifset\|else\)\>'
      \ . ':{/\%(if\|ifset\|ifchanged\|foreach\|for\|while\)\>,'
      \ . '{\(define\|block\|capture\|embed\|snippet\|snippetArea\|spaceless\|'
      \ . 'syntax\|try\|switch\|translate\|cache\|first\|last\|sep\|'
      \ . 'iterateWhile\|ifcontent\|form\|formContainer\|formContext\)\>'
      \ . ':{/\1\>'
let b:match_words = (exists('b:match_words') ? b:match_words . ',' : '')
      \ . s:latte_match_words
unlet s:latte_match_words

" Prepend: the HTML ftplugin may end b:undo_ftplugin with an :autocmd, which
" has to stay last.
let b:undo_ftplugin = 'setlocal commentstring< | unlet! b:match_words'
      \ . (exists('b:undo_ftplugin') ? ' | ' . b:undo_ftplugin : '')
