" Vim filetype plugin
" Language: Latte (Nette templating engine)
" Reuses the HTML filetype settings and switches comments to {* ... *}.

if exists('b:did_ftplugin')
  finish
endif

runtime! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
let b:did_ftplugin = 1

setlocal commentstring={*\ %s\ *}

let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '')
      \ . 'setlocal commentstring<'
