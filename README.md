# Latte syntax for Neovim

Basic syntax highlighting for [Latte](https://latte.nette.org) templates
(`*.latte`).

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
{ dir = 'JoelNiemela/latte.vim' }
```

Or git clone and add the repo to `runtimepath` yourself. It needs to come
before `$VIMRUNTIME`, which plugin managers handle for you.

## What it highlights

- HTML, with JavaScript in `<script>` and CSS in `<style>` (from the built-in
  `html` syntax)
- Latte tags: `{if $x}`, `{/if}`, `{foreach $items as $item}`,
  `{include 'file.latte'}`, `{_'text'}`, `{=expr}` …
- Expressions inside tags: `$variables`, strings, numbers, `true/false/null`,
  `as/and/or/not/in/instanceof/new`, operators, `func()` calls and
  `|filters:args`
- `{* comments *}` (with `TODO`/`FIXME`/`XXX`/`NOTE`)
- `n:attributes` and their values: `<li n:foreach="$items as $item">`
- Latte tags inside attribute values, JS strings, CSS and HTML comments

As in Latte itself, a `{` followed by whitespace or a quote is not a tag, so
`{ a: 1 }` in JavaScript is left alone.

It also sets `commentstring` to `{* %s *}` (so `gc` uses Latte comments) and
uses the HTML settings for indentation and the rest of the filetype options.

## Customizing colors

The highlight groups are `latteDelimiter`, `latteTagName`, `latteNAttr`,
`latteVariable`, `latteStringS`/`latteStringD`, `latteNumber`,
`latteConstant`, `latteKeyword`, `latteOperator`, `latteFunction`,
`latteFilter` and `latteComment`. For example:

```vim
hi link latteDelimiter PreProc
```
