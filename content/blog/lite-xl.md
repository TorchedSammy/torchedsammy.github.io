---
title: "Lite XL - A dream close to reality"
date: 2022-04-09T23:58:40-04:00
draft: false
---

A text editor is one of the programs I spend the most time in, since in my free
time I'm working on a code project. Having a comfortable, extensible text editor
is important to me.

I've been happily using Neovim for the past 1-2 years by now. Before that, while
on Windows, I was using Sublime Text around 3 years ago. Back then, I just
needed something to code in with some kind of autocomplete. I started using
Neovim a while after I moved to Linux and configured it in Vimscript with some
simple plugins and things like CoC. I kinda got hooked to programming with Lua
and using it for a lot of things (like [Hilbish](https://github.com/Rosettea/Hilbish))
and moved my Neovim config to Lua.

Pan to around February and I was suggested to try Lite XL. I've already heard of Lite
(which Lite XL is a fork of) and tried both a year ago but at the time I thought
it was lacking for me to use it. But now I daily drive it as my main and only text
editor.

The title of this post mentions Lite XL being "a dream close to reality," since
one of the reasons I used Neovim was that since there were no good GUI text editors
(except Sublime, but it also has some problems) but Lite XL is attractive for a few
reasons:
- *Fast and Lightweight* GUI text editor
- Lua scripted
- Almost the entire editor is written in Lua itself, which makes it *very* extensible

The first point could be argued against Sublime, but Lite XL is way lighter than it by
default. The C core is tiny, which means I can compile it in half a minute (!).
I also mentioned that it is very extensible. With only a couple lines of code,
I can put a clock at the corner of the screen. You can draw whatever on the
Lite XL window, which brings a lot of creativity. It's how I made this [visualizer](https://github.com/TorchedSammy/Visu)
plugin.

There's also a few other plugins, including an [LSP](https://github.com/lite-xl/lite-xl-lsp/).
If you need LSP kind icons by the way, [I have you covered.](https://github.com/TorchedSammy/lite-xl-lspkind)
The title of this post once again mentions Lite XL being a dream *close to reality.*
There are/were a few problems I've encountered. A first thing is [graphical bugs](https://github.com/lite-xl/lite-xl/issues/838)
due to my scaled screen. Another thing was that there was a few of plugins from
the central plugin repository broken. There were a few other minor things, but
close to all of these were fixed by using the master branch and using updated
plugins.

Lite XL is still fairly new and gets a lot of new additions, like the
status view no longer having hardcoded items and positions and instead has a
nice API to add, hide and move items. I've also contributed a bit, whether that
is via discussion, the plugins and pull requests I've made, like things to
improve syntax highlighting for Go and Markdown.

There's still quite a few things missing. A lot of the things I had in Neovim
I now don't have with Lite XL. Treesitter, which provided more advanced syntax
highlighting, [Telescope](https://github.com/nvim-telescope/telescope.nvim) and
Breadcrumbs (they're a bit helpful and add to the look). LSP plugin doesn't have
a few things like renaming and snippets but generally works well.

Would I recommend Lite XL? Yes, but it really depends on what you want/need.
As mentioned, the extensiblity, speed and lightness are the main selling points
but with a small ecosystem it just means if something quite general doesn't
exist, you'll have to make it yourself, and anything niche is off the table.
Atleast there's a [Vim mode](https://github.com/eugenpt/lite-xl-vibe) plugin.
