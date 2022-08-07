---
title: "Terminal Emulators"
date: 2021-11-03T23:43:40-04:00
draft: false
---

Yesterday I decided to make a custom status line for my Neovim config. In the status
line there is a section between the git status and diff indicator and the percentage
of where I am in the buffer. I thought the space between the two looked a tiny bit
too much, so with my high intelligence I used a smaller unicode block character.
It solved my problem, except with Alacritty (the terminal I use) there was a tiny piece
sticking out from the line.

![](https://modeus.is-inside.me/mVYLthyp.png)

This is kinda irritating, just looking at that block sticking out there. Does Alacritty
focus so much on performance that it can't render this properly? 
There's other cases where I've seen it broken but I don't want to screenshot them all
and this was the easiest to get since it's always staring me in my face as much as I
have Neovim writing this blog.

> Why don't you just use another terminal?

The thing is, I can't. Well I can, but they're all suboptimal in some form or the other.
My question to developers of these terminals: Is it hard to make an *efficient*
terminal? Alacritty works well, except for my font issue.

What about kitty? It's also GPU accelerated, and also uses ~100mb of RAM per instance.
I have to open 12 or 13 Alacritty instances for it to take that same amount.
[WezTerm](https://github.com/wez/wezterm) is also a GPU accelerated terminal,
quite a recent one too. It has the same problem as kitty with the RAM usage.
My device is a laptop with 4GB of ram, which is mostly used already, so having a memory
efficient terminal is actually important to me.

I've tried some other random terminals I found on GitHub like [contour](https://github.com/contour-terminal/contour)
or [darktile](https://github.com/liamg/darktile) but those specifically are so slow in Neovim
(or in my shell in the case of contour) that they're not an option at all.

Urxvt is a decent terminal but it isn't GPU accelerated and in some cases for input
is actually a bit slow (it's worked fine for me though) so I can literally see it scanning
over the entire window when I open a new file in Neovim. Atleast I can set fallback fonts
(looking at you Alacritty).

I really think at this point terminals on Windows may be better. Unless another terminal
comes around and has Alacritty's performance with how WezTerm/kitty handle fonts
and fallbacks, I may have to continue using Alacritty or deal with WezTerm's RAM usage.

And no, I'm not using st.

