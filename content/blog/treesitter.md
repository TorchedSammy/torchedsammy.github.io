---
title: "How (Not) To Use Treesitter"
date: 2022-08-07T23:41:19-04:00
draft: false
description: "My attempt at bringing Treesitter support in Lite XL."
---

> Tree-sitter is a parser generator tool and an incremental parsing library.
It can build a concrete syntax tree for a source file and efficiently update
the syntax tree as the source file is edited.

Treesitter is a efficient and fast parser for languages. It has quite a bit
of uses, the most popular one being for syntax highlighting. Since Treesitter
gives you a syntax tree, you can work with that to accurately highlight
code, even based on what is where without you having to mess with regex
that is longer than this post.

So seeing as my editor of choice, Lite XL, does *not* have a plugin for
Treesitter highlighting, I decided to make it.

# Starting Off
Lite XL plugins can be made in either Lua or C. I don't like C,
or even write it, so I had to go with Lua and find a Treesitter Lua binding.
Luckily, [ltreesitter](https://github.com/euclidianAce/ltreesitter) exists.

So after a while of reading both the ltreesitter and Treesitter documentation,
and also figuring out how Lite XL's highlighting internals worked, I made the
[initial commit](https://github.com/TorchedSammy/Evergreen.lxl/commit/8b48b52e181717afdbda9b1a87625fed58b7e16f).
One thing you will notice here is that there is a function
`Highlight:each_token`. What this does is basically ask for highlight tokens
for `idx`, that being the line. That means that on every line to highlight,
it queries the entire tree and loops over it to find the right tokens
based on the line.

It was slow as hell *and* it was still broken.  
![](https://safe.kashima.moe/mp6u2xohbv18.png)  
I realized a few things:  
- I am indexing wrong. As Lite XL's highlighter has 1 indexed lines,
and Treesitter is 0 indexed.
- I am not adding indentation or whitespace between nodes.
- There is duplicated text.

# Improvements
I made it add spacing according to the amount of columns between the adjacent
nodes, and also added spaces if the first node of a line doesn't start at 0.
That improved basic files like this:  
![](https://safe.kashima.moe/nm55f0tbx1hz.png)

But still had a problem here:  
![](https://safe.kashima.moe/pw1oyzud3t3e.png)

It turns out that Treesitter gives the same node multiple times based on
what I am querying, so the `j` there is both a parameter and a variable.
A solution to this is to just filter if the node is the same except for
the group. A simple filter function would replace subsequent nodes instead
of the last one, because the one that is returned after is the correct
one (according to my queries).

And with that, I have made it correct:  
![](https://safe.kashima.moe/t9fokvjv51ry.png)

# Even More Problems
You might have possibly thought that I was done and that I now have rich
syntax highlighting in Lite XL and while that is technically true,
it doesn't 100% work. There were a lot more problems, one of them being
that with the way I made it retrieve the nodes for the line, any multiline
nodes (like a comment block) would just not be shown and the file would
be displayed incorrectly.

Another issue is when actually editing text. Evergreen (this Lite XL
Treesitter project) asks ltreesitter to reparse the file on every
key stroke, which (surprisingly, for some reason) does not line up
text properly.

The solution to the first issue is just to check if a node takes up
more than one line. My good friend Takase [helped with that](https://github.com/TorchedSammy/Evergreen.lxl/pull/2).
The solution for the other is to make an edit to the tree.

Treesitter has a special way to highlight changes to the tree. You still
have to reparse the file, but before doing that you make an edit to the tree
which specifies a byte offset and row/column difference. If the user inserts at 0,1 then
you would make an edit to the tree that specifies the old positions as 0,0
and the new positions as 0,1. You also have to set a byte offset, so
inserting an `a` would maybe be 0 -> 1 for the byte count.

This is a problem for me as my stupid brain can't figure out how to calculate based
on the position of the cursor and also check the amount of bytes for what the user inserted.
Reparsing alone *technically* works.

# Finishing Off
You can check out the "final" thing [right here](https://github.com/TorchedSammy/Evergreen.lxl).
It would be nice for someone to make some contributions so this can be more
than a proof of concept. I feel that with my code is definitely not the best and most efficient
way of using Treesitter like this, but it does work.
