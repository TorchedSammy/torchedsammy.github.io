---
title: "Advancing Aster and Creating a Script Language"
date: 2023-02-04T20:31:31-04:00
draft: true
---

*(All code here would be under the MIT license, because that might
be needed.)*

Recently I was motivated to work on [Aster] again. A few months
ago I added support for getting palettes from various sources,
like from a `.Xresources` file, from Pywal, and from a list
of hex numbers.

An idea I have had in mind for a while was a command line shell,
which would allow quick editing and iterations of images. Now,
we should be reminded that Aster is an "image colorizer" utility;
it's job is to take an image and change around how it looks mainly
by filters that pass over the whole image. This is a command line
tool after all, and a simple one, not a masochistic GIMP in the
terminal (but honestly, doing that with some Lua might be another
fun task...)

# The Shell Part
Anyways, I'm talking about a *shell* for Aster. Here's the idea:
- Offer a nicer experience to recolor (many) images
- The ability for quick iteration. Don't like how it looks with a certain
palette? Undo, apply a new palette and recolor again

Writing a shell is easy, I've done it 2 times previously with a demo
in Javascript and my biggest project [Hilbish]. We just need to split
up a string into some parts, check what the first part is and run some code
based on that.

Added a flag to enable this shell/CLI mode:
```go
cliFlag := pflag.BoolP("cli", "c", false, "Use the Aster command line shell")

// ...

if *cliFlag {
	exit, err := runCli()
	if err != nil {
		fmt.Println(err)
	}
	os.Exit(exit)
}
```

and the `runCli` function:
```go
func runCli() {
	// ...
}
```

## User Input
First step is reading user input. While this can easily be done in
the Go standard library via an `os.Stdin.Read()` or whatever,
we don't get the nice stuff that your user shell like Bash and Zsh
have (or even Hilbish??).

To solve that problem, we will use this library: https://github.com/chzyer/readline
It's enough for our current uses, but in the future I might just move to using
Hilbish's line reader library.

So let's fill out that `runCli` function to read input:
```go
// cli.go
package main

import (
	"fmt"

	"github.com/chzyer/readline"
)

func runCli() {
	rl, err := readline.New("> ")
	if err != nil {
		return 1, err
	}

	for {
		line, err := rl.Readline()
		if err != nil {
			if err == io.EOF { // exit on Ctrl-D
				return 0, nil
			}

			return 2, err
		}

		fmt.Println(line)
	}
}
```

*TODO: screenshots*

## Commands
Next, we have to make sure that users can actually run
commands. The first thing to that is that we have to split up
the user's input into parts of the command and everything else, which
is very easy:
```go
func parseLine(line string) (string, []string) {
	line = strings.TrimSpace(line) // remove whitespace

	fields := strings.Split(line, " ")

	var name string
	args := []string{}
	for i, field := range fields {
		if i == 0 {
			name = strings.ToLower(field)
			continue
		}

		args = append(args, field)
	}

	return name, args
}
```

Next up, let's write a command based on this code.
```go
for {
	// [...]

	cmd, args := parseLine(line)
	switch cmd {
		case "hello":
			if len(cmd.args) == 0 {
				fmt.Println("Hello world!")
			} else {
				fmt.Printf("Hello %s!", cmd.args[0])
			}
	}
}
```

*TODO: screenshots*

We can add any other commands the same way. The next one we
need to do is a load command for an image. Before that, O
created a struct for the "state" which will store the image we're working with:
```go
type cliState struct{
	workingImage image.Image
}
```

Add the state somewhere before our shell loop, and then make the load command:
```go
	case "load":
		if len(cmd.args) == 0 {
			fmt.Println("Missing required path to load image")
		}

		path := cmd.args[0]
		f, err := os.Open(path)
		if err != nil {
			fmt.Println("Could not open input file")
			continue
		}

		// !! don't forget to import supported formats !!
		img, _, err := image.Decode(f)
		if err != nil {
			fmt.Println("Could not decode image:", err)
			continue
		}

		state.workingImage = img
```

## Other Features
You know how I mentioned undo as one of our advantages for this shell?
That's easy: store a slice of images and whenever a change was
made, append the edited image to our slice.

Then to actually undo that, we can reslice to set the current working image.

# The Scripting Language
The exiting part!  
At the current point, the Aster shell works good enough; we have commands
defined in a basic way and they run. But to add a little spice to it.
An advantage is that a user will be able to define certain filters
so that if they want an image to appear a specific way all the time.
A simple example of that is a single command to turn an image monochrome
and then shift it to a blue hue.

This is more of a DSL, but let's say it's a script anyway.
There are a few steps to interpreting a language. This post is not
gonna go into too much detail about writing parts of an interpreted
language as there are plenty of better resources out there. Nonetheless,
I'll still be writing about my attempt to doing it.

## Step 1: Lexing
The first step is turning some source code into a set of tokens.
I used [this](https://www.aaronraff.dev/blog/how-to-write-a-lexer-in-go) as
my resource for writing a lexer. The TLDR is that we read the input
rune by rune, and output a certain token based on what's read.

We will define a set of tokens:
```go
type Token int
const (
	EOF

	IDENT
	STRING
)
```

And define our lexer:
```go
type Position struct {
	Line int
	Column int
}

type Lexer struct {
	pos Position
	reader *bufio.Reader
}

func NewLexer(reader io.Reader) *Lexer {
	return &Lexer{
		pos: Position{Line: 1, Column: 0},
		reader: bufio.NewReader(reader),
	}
}
```

So to actually lex our source into tokens, we'll have this `Next`
function that can be ran in a loop to get a list of tokens
from a source file:
```go
func (l *Lexer) Next() (Token, Position, string) {
	for {
		r, _, err := l.reader.ReadRune()
		if err != nil {
			if err == io.EOF {
				return EOF, l.pos, ""
			}

			panic(err) // ?
		}

		l.pos.Column++

		switch r {
			case '\n':
				// do things with newLine
				l.pos.Line++
				l.pos.Column = 0
		}
	}
}
```

Now we have a completely useless lexer! To make it more useful,
let's have it turn `"hello world"` into a string token:

```go
	case '"':
		start := l.pos // save the real starting position
		return STRING, start, l.scanString()
```

And our scanString function will be like so:
```go
func (l *Lexer) scanString() string {
	sb := strings.Builder{}
	escaped := false

	for {
		r, _, err := l.reader.ReadRune()
		if err != nil {
			if err == io.EOF {
				return sb.String()
			}
		}
		l.pos.Column++

		switch r {
			case '"':
				return sb.String()
			default:
				sb.WriteRune(r)
		}
	}
}
```

Next, we'll want to parse identifiers. This can go in our default
case for the switch statement.
```
	default:
		if unicode.IsLetter(r) {
			start := l.pos
			l.Back() // to rescan part of the ident in the method below
			ident := l.scanIdent()

			return IDENT, start, ident
		}
```

We want to be able to go back so that the first character of the
identifier doesn't get cut off:
```go
func (l *Lexer) Back() {
	l.reader.UnreadRune()
	l.pos.Column--
}
```

And then actually scan our identifier:
```go
func (l *Lexer) scanIdent() string {
	sb := strings.Builder{}

	for {
		r, _, err := l.reader.ReadRune()
		if err != nil {
			if err == io.EOF {
				return sb.String()
			}
		}

		l.pos.Column++

		if unicode.IsLetter(r) {
			sb.WriteRune(r)
			continue
		}

		l.Back() // unread non-ident rune
		return sb.String()
	}
}
```

With this code here, it's pretty easy to plug in new matches for 
something like a number.

![](https://safe.kashima.moe/s7ufxm1w1139.png)  
And we can list out our tokens!

## Step 2: Parsing into an AST
First of all: what is an AST?
Well, this is the result from Google:
> An Abstract Syntax Tree, or AST, is a tree representation of the
source code of a computer program that conveys the structure of
the source code. Each node in the tree represents a construct occurring
in the source code.

An AST is a representation of our source code as a tree.
[Wikipedia is good at describing things.](https://en.wikipedia.org/wiki/Abstract_syntax_tree)

We can handle showing syntax errors in the parsing step and make it
easy to represent our source code into something easily executable!
(or something so)

Now, I don't want to show my code for parsing here because I think
it's a bit of a mess, but imagine that you have a function that
loops over tokens and creates a list of nodes based on those
tokens.

Here's a basic jist of it:
```go
type Identifier struct{
	Name string // name of identifier
	Pos Position
}

type LiteralType int
const (
	StringLiteral LiteralType = iota
)

type Literal struct{
	Value string
	Pos Position
	Typ LiteralType
}

func Parse(r io.Reader) {
	lx := NewLexer(r)

	// for simplicity in this blog post: you'd want to use an actual interface
	ops := []interface{}
	for {
		token, pos, lit := lx.Next()
		if token == EOF {
			break
		}

		case IDENT:
			ops = append(ops, Identifier{
				Name: lit,
				Pos: pos,
			})
		case STRING:
			ops = append(ops, Literal{
				Value: lit,
				Pos: pos
				Typ: StringLiteral,
			})
		// [...]
	}
}
```

## Step 3: Interpreting
TODO

# So.. Asterscript?
Going through and making this was probably the most interesting thing
I've done in a while, and while a few people on the r/Unixporn server
might say this is over-engineering for an "image colorizer" utility,
I say that Aster being more capable and powerful than others in
the small scope of what it does is a win for me.

"Asterscript" as an unofficial name, is designed for it to be easy to
parse (hopefully). Any lone identifier is a command, and whatever after
it are the arguments. This makes it pluggable as is for our shell,
exactly like shell script.

Here's a demo:
```
var #who = "world"
print "hello"
print #who
```
which should print "hello" and then "world" on separate lines.
