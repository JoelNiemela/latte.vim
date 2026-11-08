" Vim indent file
" Language: Latte (Nette templating engine)
" HTML indenting plus Latte blocks: the content of {if}, {foreach}, {define},
" {block} ... is indented one level, and {else}, {elseif} and {/...} line up
" with the opening tag.

if exists('b:did_indent')
  finish
endif

" Like syntax/latte.vim, use the HTML indent script from $VIMRUNTIME:
" GetLatteIndent() builds on its HtmlIndent().
if get(g:, 'latte_html_from_rtp', 0)
  runtime! indent/html.vim
else
  let s:rtp_save = &runtimepath
  try
    let &runtimepath = escape($VIMRUNTIME, ',\')
    runtime! indent/html.vim
  finally
    let &runtimepath = s:rtp_save
  endtry
endif

if !exists('*HtmlIndent')
  " Some other HTML indent script was loaded; keep its indentexpr.
  finish
endif

setlocal indentexpr=GetLatteIndent()

if exists('*GetLatteIndent')
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

" HtmlIndent_FindTagStart() (from $VIMRUNTIME/indent/html.vim) finds the '<'
" of a start tag ending on lnum by pairing '<\w' with '\S>', so every '->'
" or '=>' in an attribute like value="{$field->name}" counts as another tag
" end and it finds the wrong line. Redefine it, unchanged except that in Latte
" buffers '->' and '=>' don't count. It is a global function that other
" HTML-like indent scripts may call; in other buffers it behaves as before.
function! HtmlIndent_FindTagStart(lnum)
  let tag_end = &filetype ==# 'latte' ? '[^[:space:]=-]>' : '\S>'
  let idx = match(getline(a:lnum), tag_end . '\s*$')
  if idx > 0
    call cursor(a:lnum, idx)
    let lnum = searchpair('<\w', '' , tag_end, 'bW', '', max([a:lnum - b:html_indent_line_limit, 0]))
    if lnum > 0
      return [lnum, 1]
    endif
  endif
  return [a:lnum, 0]
endfunction

" Paired tags whose content is indented.
let s:block_tags = '\%(if\|ifset\|ifchanged\|ifcontent\|foreach\|for\|while\|'
      \ . 'first\|last\|sep\|iterateWhile\|define\|block\|capture\|embed\|'
      \ . 'snippet\|snippetArea\|spaceless\|try\|switch\|translate\|cache\|'
      \ . 'form\|formContainer\|formContext\)'
" Tags that end the previous branch and start a new one.
let s:middle_tags = '\%(else\|elseif\|elseifset\|case\)'

" Is (lnum, col) the '{' that starts a Latte tag?
function! s:IsTagStart(lnum, col) abort
  if !exists('b:current_syntax')
    return 1
  endif
  return synIDattr(synID(a:lnum, a:col, 1), 'name') ==# 'latteDelimiter'
endfunction

" Change in Latte block depth over line lnum: +1 for each opening block tag,
" -1 for each closing one. {else} and friends don't count.
function! s:Net(lnum) abort
  let line = getline(a:lnum)
  let net = 0
  let start = 0
  while 1
    let m = matchstrpos(line, '{/\=\h\w*\|{/}', start)
    if m[1] < 0
      break
    endif
    let start = m[2]
    if !s:IsTagStart(a:lnum, m[1] + 1)
      continue
    endif
    if m[0] ==# '{/}'
      let net -= 1
    elseif matchstr(m[0], '\h\w*') =~# '^' . s:block_tags . '$'
      let net += m[0][1] ==# '/' ? -1 : 1
    endif
  endwhile
  return net
endfunction

" 1 if line lnum starts with a tag that is dedented to the level of its
" opening tag: {/if}, {else}, {elseif ...}, {case ...}, {default}.
function! s:Lead(lnum) abort
  let line = getline(a:lnum)
  let col = match(line, '^\s*\zs{\%(/' . s:block_tags . '\>\|/}\|' . s:middle_tags . '\>\|default}\)')
  return col >= 0 && s:IsTagStart(a:lnum, col + 1)
endfunction

" Change in HTML depth over line lnum, ignoring anything inside Latte tags and
" comments. Only used after multi-line Latte tags, where HtmlIndent() can't
" be used; void elements and <p> (which HtmlIndent() doesn't indent by
" default) don't count.
function! s:HtmlNet(lnum) abort
  let line = getline(a:lnum)
  let net = 0
  let start = 0
  while 1
    let m = matchstrpos(line, '<\zs/\=\a[[:alnum:]-]*', start)
    if m[1] < 0
      break
    endif
    let start = m[2]
    if tolower(substitute(m[0], '^/', '', '')) =~# '^\%(area\|base\|br\|col\|embed\|hr\|img\|input\|link\|meta\|param\|source\|track\|wbr\|p\)$'
      continue
    endif
    if exists('b:current_syntax') && synIDattr(synID(a:lnum, m[1], 0), 'name') =~# '^latte'
      continue
    endif
    let net += m[0][0] ==# '/' ? -1 : 1
  endwhile
  return net
endfunction

" Is line lnum the continuation of a multi-line Latte tag or comment, or
" inside a {syntax off} block?
function! s:InLatte(lnum) abort
  if !exists('b:current_syntax')
    return 0
  endif
  let line = getline(a:lnum)
  let col = match(line, '\S') + 1
  if col == 0
    return 0
  endif
  let names = map(synstack(a:lnum, col), 'synIDattr(v:val, "name")')
  if index(names, 'latteSyntaxOff') >= 0 || index(names, 'latteNSyntaxOff') >= 0
    return 1
  endif
  if index(names, 'latteTag') < 0 && index(names, 'latteComment') < 0
    return 0
  endif
  " A line that starts with '{' or '{*' starts a new tag/comment.
  return !(line[col - 1] ==# '{' && (line[col] ==# '*' || s:IsTagStart(a:lnum, col)))
endfunction

" The line HtmlIndent() aligns with when v:lnum is inside a start tag (see
" s:InsideTag() in $VIMRUNTIME/indent/html.vim), or 0.
function! s:AttrLine(lnum) abort
  let text = getline(a:lnum)
  if text =~# '^\s*<'
    return 0
  endif
  let names = map(synstack(a:lnum, match(text, '\S') + 1), 'synIDattr(v:val, "name")')
  if index(names, 'htmlTag') < 0 && index(names, 'htmlScriptTag') < 0
    return 0
  endif
  if index(names, 'htmlString') >= 0
    return a:lnum - 1
  endif
  let lnum = a:lnum
  while lnum > 1
    let lnum -= 1
    let text = getline(lnum)
    if text =~# '\s[_a-zA-Z0-9-]\+="' || text =~# '<\w\+\%(-\w\+\)*\%(\s\+\w\|$\)'
      return lnum
    endif
  endwhile
  return 0
endfunction

function! GetLatteIndent() abort
  let ind = s:Indent()
  " The = operator changes indents without telling the syntax engine, which
  " would otherwise resume parsing this line at a stale column when the next
  " line is indented, and misparse it. Leave it on the line above instead,
  " which = has finished with.
  call synID(max([1, v:lnum - 1]), 1, 0)
  return ind
endfunction

function! s:Indent() abort
  let prev = prevnonblank(v:lnum - 1)
  if prev == 0
    return 0
  endif
  if s:InLatte(v:lnum)
    return -1
  endif
  let sw = shiftwidth()

  " After a multi-line tag or comment, continue from the line it started on.
  " (A closing HTML tag is still lined up with its opening tag below.)
  if s:InLatte(prev) && getline(v:lnum) !~# '^\s*</'
    let ref = prev
    while ref > 1 && s:InLatte(ref)
      let ref -= 1
    endwhile
    let depth = s:Lead(ref) - s:Lead(v:lnum)
    for lnum in range(ref, prev)
      let depth += s:Net(lnum) + s:HtmlNet(lnum)
    endfor
    return max([0, indent(ref) + depth * sw])
  endif

  let attr = s:AttrLine(v:lnum)

  " HtmlIndent() normally continues from state it saved for the previous
  " line, which doesn't include the Latte indent added below; make it start
  " fresh from the actual indent of the previous lines instead.
  let b:hi_lasttick = -2
  let ind = HtmlIndent()
  if ind < 0
    return ind
  endif

  " A closing HTML tag lines up with its opening tag, which is already at the
  " right Latte depth.
  if getline(v:lnum) =~# '^\s*</'
    return ind
  endif

  if attr > 0
    " Inside a start tag HtmlIndent() aligns with an attribute on line attr;
    " add the Latte depth reached since then.
    let depth = s:Lead(attr) - s:Lead(v:lnum)
    for lnum in range(attr, prev)
      let depth += s:Net(lnum)
    endfor
  else
    let depth = s:Net(prev) + s:Lead(prev) - s:Lead(v:lnum)
  endif
  return max([0, ind + depth * sw])
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
