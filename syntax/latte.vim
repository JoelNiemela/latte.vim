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
"
" By default html.vim, and the javascript.vim/css.vim it includes, are loaded
" from $VIMRUNTIME only. Replacements such as vim-polyglot's don't let template
" tags into their regions, so Latte inside <script> would go unhighlighted.
" Set g:latte_html_from_rtp = 1 to use whatever 'runtimepath' finds.
" ---------------------------------------------------------------------------
if get(g:, 'latte_html_from_rtp', 0)
  runtime! syntax/html.vim
else
  let s:rtp_save = &runtimepath
  try
    let &runtimepath = escape($VIMRUNTIME, ',\')
    runtime! syntax/html.vim
  finally
    let &runtimepath = s:rtp_save
  endtry
endif
unlet! b:current_syntax

syn case match

" ---------------------------------------------------------------------------
" Expressions (used inside {tags} and n:attribute values)
" ---------------------------------------------------------------------------
syn cluster latteExprBase contains=latteVariable,latteNumber,latteConstant,latteKeyword,latteOperator,latteFunction,latteClass,latteComma,latteFilter,latteBraces,latteParens,latteBrackets
syn cluster latteExpr     contains=@latteExprBase,latteStringS,latteStringD

syn match   latteOperator contained +[-+*/%=<>!?:.&|~^@]+
syn match   latteNumber   contained +\<\d\+\%(\.\d\+\)\=\>+
syn match   latteVariable contained +\$\h\w*+

syn region  latteStringS  contained start=+'+ skip=+\\\\\|\\'+ end=+'+
syn region  latteStringD  contained start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=latteVariable

" ENT_QUOTES, PHP_EOL ...
syn match   latteConstant contained +\<\u[A-Z0-9_]\+\>\%(\s*(\|\\\|::\)\@!+
" Class::CONSTANT, Enum::Case, Foo::class
syn match   latteConstant contained +\%(::\)\@2<=\h\w*\>\%(\s*(\)\@!+
syn keyword latteConstant contained true false null TRUE FALSE NULL
syn keyword latteKeyword  contained as and or not xor in fn match
syn keyword latteKeyword  contained new instanceof nextgroup=latteNewClass skipwhite

syn match   latteFunction contained +\h\w*\ze\s*(+

" Class names: \Kattis\Site, Kattis\Site, Site::..., new Foo, instanceof Foo
syn match   latteClass    contained +\\\=\h\w*\%(\\\h\w*\)\+\%(\w\|\\\|\s*(\)\@!+
syn match   latteClass    contained +\\\=\h\w*\%(\\\h\w*\)*\ze::+
syn match   latteNewClass contained +\\\=\h\w*\%(\\\h\w*\)*+

" Named arguments: {include x, class: 'info'}, func($a, name: $v)
syn match   latteComma    contained +,+ nextgroup=latteNamedArg skipwhite skipnl
syn match   latteNamedArg contained +\h\w*\ze\s*:\%(:\)\@!+

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
syn cluster latteContainedIn contains=cssDefinition,cssAttrRegion,cssFunction,htmlScriptTag

syn region  latteTag matchgroup=latteDelimiter start=+{/\=\ze[^[:space:]'"*}]+ end=+}+ contains=latteTagName,@latteExpr containedin=@latteContainedIn

" The word right after '{' or '{/' is the tag name, unless it is a function
" call: {T('...')}, {url_for(...)} print the result of the call.
syn match   latteTagName contained +\%({/\=\)\@2<=\h\w*\%(\w\|\s*(\)\@!+

" Block names: {block caption}, {define name, ...}, {include name, ...},
" {include block $name}
syn match   latteTagName contained +\%({\)\@1<=\%(block\|define\|include\|embed\|snippet\|snippetArea\|ifset\)\>\%(\s*(\)\@!+ nextgroup=latteBlockName,latteBlockKeyword skipwhite
syn match   latteBlockName contained +#\=\h[[:alnum:]_-]*\%([[:alnum:]_-]\|\s*[(:\\]\)\@!+
syn match   latteBlockKeyword contained +\<block\>\ze\s\+[$#[:alpha:]_]+ nextgroup=latteBlockName skipwhite

" {* comments *}
syn region  latteComment start=+{\*+ end=+\*}+ contains=latteTodo,@Spell containedin=@latteContainedIn
syn keyword latteTodo contained TODO FIXME XXX NOTE

" {syntax off} ... {/syntax}: no Latte tags in between. The region's body
" starts at the '{' (rs=s) so that only latteSyntaxOffTag can match the
" {syntax off} tag itself; it stops right before {/syntax}, which is then
" highlighted as a normal tag.
syn region  latteSyntaxOff start=+{syntax\s\+off}+rs=s end=+{/syntax}+me=s-1 contains=latteSyntaxOffTag containedin=@latteContainedIn
syn region  latteSyntaxOffTag contained matchgroup=latteDelimiter start=+{\%(syntax\s\+off}\)\@=+ end=+}+ contains=latteTagName

" ---------------------------------------------------------------------------
" n:attributes: <div n:if="$cond" n:foreach="$items as $item" n:class=...>
" ---------------------------------------------------------------------------
syn match   latteNAttr    contained +\<n:[[:alnum:]_-]\++ nextgroup=latteNAttrEq
syn match   latteNAttrEq  contained +\s*=\s*+ nextgroup=latteNAttrValD,latteNAttrValS
syn region  latteNAttrValD contained matchgroup=latteNAttrQuote start=+"+ end=+"+ contains=@latteExprBase,latteStringS
syn region  latteNAttrValS contained matchgroup=latteNAttrQuote start=+'+ end=+'+ contains=@latteExprBase,latteStringD

" <span n:syntax="off">...</span>: no Latte tags in the element's content.
" The start tag itself is still highlighted (htmlTag, from rs=s).
" Approximation: the content ends at the next closing tag.
syn region  latteNSyntaxOff start=+<\a[[:alnum:]-]*\_[^>]\{-}\<n:syntax\s*=\s*["']off["']+rs=s end=+</+me=s-1 contains=htmlTag

" ---------------------------------------------------------------------------
" Hook into html.vim: @htmlPreproc is allowed inside tags, attribute strings,
" <script>, <style>, comments, etc.; @htmlArgCluster inside <tag ...>.
" ---------------------------------------------------------------------------
syn cluster htmlPreproc    add=latteTag,latteComment,latteSyntaxOff,latteNSyntaxOff
syn cluster htmlArgCluster add=latteNAttr

" <script type="text/html"> holds HTML templates, not JavaScript. Defined
" after html.vim's javaScript region so it wins for these script tags.
syn cluster latteHtmlInScript contains=@Spell,htmlTag,htmlEndTag,htmlSpecialChar,htmlComment,htmlLink,@htmlPreproc
syn region  latteHtmlScript start=+<script\>\ze\_[^>]*\<type\s*=\s*["']\=text/\%(html\|template\|x-template\)\>+ keepend end=+</script\_[^>]*>+me=s-1 contains=htmlScriptTag,@latteHtmlInScript

" ---------------------------------------------------------------------------
" Highlighting
" ---------------------------------------------------------------------------
hi def link latteDelimiter  Special
hi def link latteTagName    Statement
hi def link latteBlockKeyword latteTagName
hi def link latteBlockName  Identifier
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
hi def link latteClass      Type
hi def link latteNewClass   latteClass
hi def link latteNamedArg   Special
hi def link latteFilter     Function
hi def link latteFilterPipe latteOperator
hi def link latteComment    Comment
hi def link latteTodo       Todo

let b:current_syntax = 'latte'

let &cpo = s:cpo_save
unlet s:cpo_save
