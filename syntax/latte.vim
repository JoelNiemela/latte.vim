" Vim syntax file
" Language:    Latte (Nette templating engine) <https://latte.nette.org>
" Description: HTML highlighting plus Latte {tags}, {* comments *} and
"              n:attributes.
"
" Neovim/Vim ship a syntax/latte.vim for an unrelated Lisp-like language of
" the same name. This plugin sits earlier in 'runtimepath', so it is sourced
" first, sets b:current_syntax, and the bundled file bails out.

if exists('b:current_syntax')
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

" ---------------------------------------------------------------------------
" HTML base (this also brings in JavaScript for <script> and CSS for <style>)
" ---------------------------------------------------------------------------
runtime! syntax/html.vim
unlet! b:current_syntax

syn case match

" ---------------------------------------------------------------------------
" Expressions (used inside {tags} and n:attribute values)
" ---------------------------------------------------------------------------
syn cluster latteExprBase contains=latteVariable,latteNumber,latteConstant,latteKeyword,latteOperator,latteFunction,latteFilter,latteBraces,latteParens,latteBrackets
syn cluster latteExpr     contains=@latteExprBase,latteStringS,latteStringD

syn match   latteVariable contained +\$\h\w*+
syn match   latteNumber   contained +\<\d\+\%(\.\d\+\)\=\>+
syn keyword latteConstant contained true false null TRUE FALSE NULL
syn keyword latteKeyword  contained as and or not xor in instanceof new fn

syn region  latteStringS  contained start=+'+ skip=+\\\\\|\\'+ end=+'+
syn region  latteStringD  contained start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=latteVariable

syn match   latteOperator contained +[-+*/%=<>!?:.&|~^@]+
syn match   latteFunction contained +\h\w*\ze\s*(+
" |filter and |filter:arg  (but not the || operator)
syn match   latteFilter   contained +|\@1<!|\s*\h\w*+ contains=latteFilterPipe
syn match   latteFilterPipe contained +|+

" Balanced brackets, so nested {} [] () don't end a tag early.
syn region  latteBraces   contained transparent start=+{+ end=+}+ contains=@latteExpr
syn region  latteParens   contained transparent start=+(+ end=+)+ contains=@latteExpr
syn region  latteBrackets contained transparent start=+\[+ end=+]+ contains=@latteExpr

" ---------------------------------------------------------------------------
" Tags: {if $x}, {/if}, {$var|filter}, {=expr}, {_'text'}, {include 'x'} ...
" Like Latte itself, a '{' followed by whitespace or a quote is not a tag, so
" `{ a: 1 }` in JavaScript/CSS is left alone.
" ---------------------------------------------------------------------------
syn region  latteTag matchgroup=latteDelimiter start=+{/\=\ze[^[:space:]'"*}]+ end=+}+ contains=latteTagName,@latteExpr containedin=cssDefinition
" The word right after '{' or '{/' is the tag name.
syn match   latteTagName contained +\%({/\=\)\@2<=\h\w*+

" {* comments *}
syn region  latteComment start=+{\*+ end=+\*}+ contains=latteTodo,@Spell containedin=cssDefinition
syn keyword latteTodo contained TODO FIXME XXX NOTE

" ---------------------------------------------------------------------------
" n:attributes: <div n:if="$cond" n:foreach="$items as $item" n:class=...>
" ---------------------------------------------------------------------------
syn match   latteNAttr    contained +\<n:[[:alnum:]_-]\++ nextgroup=latteNAttrEq
syn match   latteNAttrEq  contained +\s*=\s*+ nextgroup=latteNAttrValD,latteNAttrValS
syn region  latteNAttrValD contained matchgroup=latteNAttrQuote start=+"+ end=+"+ contains=@latteExprBase,latteStringS
syn region  latteNAttrValS contained matchgroup=latteNAttrQuote start=+'+ end=+'+ contains=@latteExprBase,latteStringD

" ---------------------------------------------------------------------------
" Hook into html.vim: @htmlPreproc is allowed inside tags, attribute strings,
" <script>, <style>, comments, etc.; @htmlArgCluster inside <tag ...>.
" ---------------------------------------------------------------------------
syn cluster htmlPreproc    add=latteTag,latteComment
syn cluster htmlArgCluster add=latteNAttr

" ---------------------------------------------------------------------------
" Highlighting
" ---------------------------------------------------------------------------
hi def link latteDelimiter  Special
hi def link latteTagName    Statement
hi def link latteNAttr      latteTagName
hi def link latteNAttrQuote latteDelimiter
hi def link latteVariable   Identifier
hi def link latteStringS    String
hi def link latteStringD    String
hi def link latteNumber     Number
hi def link latteConstant   Constant
hi def link latteKeyword    Keyword
hi def link latteOperator   Operator
hi def link latteFunction   Function
hi def link latteFilter     Function
hi def link latteFilterPipe latteOperator
hi def link latteComment    Comment
hi def link latteTodo       Todo

let b:current_syntax = 'latte'

let &cpo = s:cpo_save
unlet s:cpo_save
