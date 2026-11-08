# Latte syntax for Neovim

Syntax highlighting, indentation and `%` matching for
[Latte](https://latte.nette.org) templates (`*.latte`).

Neovim already detects `*.latte` as filetype `latte`, but the syntax file it
ships for that name is for an unrelated Lisp-like language. This plugin
overrides it.

## Install

vim-plug:

```vim
Plug 'JoelNiemela/latte.vim'
```

lazy.nvim:

```lua
{ 'JoelNiemela/latte.vim' }
```

Or git clone and add the repo to `runtimepath` yourself. It needs to come
before `$VIMRUNTIME`, which plugin managers handle for you.

### vim-polyglot

[vim-polyglot](https://github.com/sheerun/vim-polyglot) ships its own copy of
the Lisp-like `syntax/latte.vim`. If it ends up ahead of this plugin in
`runtimepath`, `*.latte` files get that syntax instead and look mostly
unhighlighted. With vim-plug this happens after any lazy-loaded plugin
(`'for'`/`'on'`) loads, because vim-plug then rebuilds `runtimepath` in the
order of your `Plug` lines. Disable polyglot's version before it loads:

```vim
let g:polyglot_disabled = ['latte']
```

Neovim still detects `*.latte` as filetype `latte` without it.

## HTML, JavaScript and CSS

Latte files are highlighted as HTML, with JavaScript in `<script>` and CSS in
`<style>`, and indented with the HTML indent script. These always come from
`$VIMRUNTIME`, even if another plugin (such as vim-polyglot) replaces them
for `.html`/`.js`/`.css` files. The built-in syntax files let template tags
into their regions; replacements usually don't, and Latte inside `<script>`
then goes unhighlighted. To use whatever `runtimepath` finds instead:

```vim
let g:latte_html_from_rtp = 1
```

## What it highlights

- Latte tags: `{if $x}`, `{/if}`, `{foreach $items as $item}`,
  `{include 'file.latte'}`, `{_'text'}`, `{=expr}` …
- Function calls printed as tags, like `{T('Hello')}` or `{url_for('home')}`,
  are highlighted as function calls, not tag names
- Block names: `{block content}`, `{define row, $item}`,
  `{include row, item: $x}`, `{include block $name}`
- Expressions inside tags: `$variables`, strings, numbers, `true/false/null`,
  keywords (`as`, `instanceof`, `new`, `fn`, `match` …), operators, `func()`
  calls, `|filters:args`, named arguments (`class: 'info'`), class names
  (`\App\Model\User`, `Status::`) and constants (`Status::Active`,
  `ENT_QUOTES`)
- `{* comments *}` (with `TODO`/`FIXME`/`XXX`/`NOTE`)
- `n:attributes` and their values: `<li n:foreach="$items as $item">`
- Latte tags inside attribute values, `<script>` and `<style>` (including CSS
  functions), HTML comments and `<script>` start tags
- `{syntax off}` … `{/syntax}` and `n:syntax="off"`: no Latte tags inside
- `<script type="text/html">` templates as HTML rather than JavaScript

As in Latte itself, a `{` followed by whitespace or a quote is not a tag, so
`{ a: 1 }` in JavaScript is left alone.

## Indentation

HTML indentation, plus Latte blocks: the content of `{if}`, `{foreach}`,
`{define}`, `{block}`, `{capture}` … is indented one level, and `{else}`,
`{elseif}` and `{/…}` line up with their opening tag. Lines inside
multi-line tags and comments, and inside `{syntax off}`, keep their indent.

Attributes and `<p>` follow the HTML indent settings. For example, to
indent attributes on their own lines by one level and indent inside `<p>`:

```vim
let g:html_indent_attribute = 1
let g:html_indent_inctags = 'p'
```

## Other settings

- `commentstring` is `{* %s *}`, so `gc` uses Latte comments.
- With matchit (loaded by default in Neovim), `%` jumps between `{if}`,
  `{elseif}`, `{else}` and `{/if}`, between `{foreach}` and `{/foreach}`,
  `{define}` and `{/define}`, and so on, as well as between HTML tags.
- The rest of the filetype options come from the HTML ones.

## Customizing colors

The highlight groups are `latteDelimiter`, `latteTagName`, `latteBlockName`,
`latteNAttr`, `latteVariable`, `latteStringS`/`latteStringD`, `latteNumber`,
`latteConstant`, `latteKeyword`, `latteOperator`, `latteFunction`,
`latteClass`, `latteNamedArg`, `latteFilter` and `latteComment`. For
example:

```vim
hi link latteDelimiter PreProc
```
