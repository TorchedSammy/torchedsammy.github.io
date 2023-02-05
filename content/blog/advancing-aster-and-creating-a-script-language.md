---
title: "Advancing Aster and Creating a Script Language"
date: 2023-02-04T20:31:31-04:00
draft: false
---

> (All code here would be under the MIT license, because that might
be needed.)

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

# So.. Asterscript?
"Asterscript," as an unofficial name, is designed to a (hopefully)
easy to parse language for our shell. Any lone identifier is a command,
and whatever after it are the arguments. This makes it pluggable as is
for our use in a terminal shell.

Here's a demo:
```
// comments are written like this

// set a custom prompt
prompt "-> "

// load our image file for operations
load "filename"
lightnessSwap
recolor @dither=false // @name would be switches (commandoptions) but im skeptical about the syntax

var h = 6 / #pi // # references variables, and pi is builtin
print "wow a number: " #h // as shown before (if you didnt notice) functions dont need parens
```

# The Shell Part
Anyways, I'm talking about a *shell* for Aster. Here's the idea:
- Offer a nicer experience to recolor (many) images
- The ability for quick iteration. Don't like how it looks with a certain
palette? Undo, apply a new palette and recolor again. Done in a few seconds.

Writing a shell is easy, I've done it 2 times previously with a demo
in Javascript and my biggest project [Hilbish]. For a basic version,
We just need to split up a string into some parts, check what the first
part is and run some code based on that.

Added a flag to enable this shell/CLI mode:
```go
cliFlag := flag.BoolP("cli", "c", false, "Use the Aster command line shell")

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
	"io"

	"github.com/chzyer/readline"
)

func runCli() {
	rl, _ := readline.New("-> ")

	for {
		line, err := rl.Readline()
		if err == io.EOF { // exit on ctrld
			return 0, nil
		}

		fmt.Println(line)
	}
}
```

![](https://safe.kashima.moe/ucjbhn7v8ut4.png)
> World's most useless shell.

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
	// loop over our split up input
	for i, field := range fields {
		// if this is the first field, we can assure it's the command
		// so set the name and then go to the next step of just pushing args
		// to our slice
		if i == 0 {
			name = field
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
			if len(args) == 0 {
				fmt.Println("Hello world!")
			} else {
				fmt.Printf("Hello %s!", args[0])
			}
	}
}
```

![](https://safe.kashima.moe/34ite5s4tua7.png)

We can add any other commands the same way. The next one we
need to do is a load command for an image. Before that, I
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
		f, _ := os.Open(path) // ignore error for more clarity

		// !! don't forget to import supported formats !!
		img, _, err := image.Decode(f)

		state.workingImage = img
```

## Other Features
You know how I mentioned undo as one of our advantages for this shell?
That's easy: store a slice of images and whenever a change was
made, append the edited image to our slice. We can do that in our
previously declared cliState struct:
```go
type cliState struct{
	workingImage image.Image
	prevImageStates []image.Image
}
```

Then to actually undo that, we can reslice to set the current working image.
We'll make a convenient function to do that:
```go
func (s *cliState) undoImg() {
	prevIdx := len(s.prevImageStates) - 1
	// get the last image before the current one
	prevWorkingImg := s.prevImageStates[prevIdx]
	// and then "pop" remove it from our slice
	s.prevImageStates = s.prevImageStates[:prevIdx]

	// so now we can set the current image to work on as the last image
	s.workingImage = prevWorkingImg
}
```

# The Scripting Language
> The exiting part!

At the current point, the Aster shell works good enough; we have commands
defined in a basic way and they run. But to add a little spice to it
and make it better, we can design a scripting language for our shell.

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
	EOF Token = iota

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
The reason for using `bufio` here is that we need to be able
to unread a character.

So to actually lex our source into tokens, we'll have this `Next`
function that can be ran in a loop to get a list of tokens
from a source file:
```go
func (l *Lexer) Next() (Token, Position, string) {
	for {
		// to explain it very very simply, a rune
		// is a character in go. so here, we're reading
		// character by character
		r, _, err := l.reader.ReadRune()
		// may want to check for other errors
		// but if we reach eof we're done
		if err == io.EOF {
			return EOF, l.pos, ""
		}

		l.pos.Column++

		switch r {
			case '\n':
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

	for {
		r, _, err := l.reader.ReadRune()
		if err == io.EOF {
			return sb.String()
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
```go
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
		if err == io.EOF {
			return sb.String()
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

We'll add a `String` method to our token type to be able to see
what token it is easily.
```go
var tokenIdentMap = map[Token]string{
	EOF: "EOF",

	IDENT: "IDENT",
	STRING: "STRING",
}

func (t Token) String() string {
	name := tokenIdentMap[t]
	return name
}
```

Let's make our shell tokenize user input into tokens and then print
them. This will be done after we print the line in our shell loop.
```go
// turns our line into an io.Reader interface
lx := NewLexer(strings.NewReader(line))

for {
	token, pos, lit := lx.Next()
	if token == EOF {
		break
	}

	fmt.Printf("%d:%d %s %s\n", pos.Line, pos.Column, token, lit)
}
```

![](https://safe.kashima.moe/w401qu17w731.png)

> It tokenizes!

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

The first step I did was declare an interface for all nodes in our
AST to implement. This is based on Go's own AST package.
```go
type Node interface{
	Start() Position
	End() Position
}
```

Now I declare some structs for the basic parts of Asterscript's 
syntax. One of those would be running a command (or calling a function):
```go
type Call struct {
	Pos Position
	Name string // name of command
}

func (c Call) Start() Position { return c.Pos }
func (c Call) End() Position { return c.Pos }
```
Functions can have arguments passed to them though right? So we need to
store that in our Call struct. But what type would they be?

I made a Value type to hold Asterscript values:
```go
type Value struct{
	Pos Position
	Val string
	Kind ValueKind
}
```
And the `Kind` here would basically tell us what the type of the value is.
```go
type ValueKind int
const (
	EmptyKind ValueKind = iota
	StringKind
)
```
So then we can add it to our Call struct:
```go
type Call struct {
	Pos Position
	Name string // name of command
	Arguments []Value // arguments to the command
}
```

Now we can go ahead and attempt parsing! We will have a very basic
parser that only attempts to parse calls. In our parse function,
the first step is to get a new lexer so we can loop over the tokens,
and also have a slice to store our nodes:
```go
func Parse(r io.Reader) ([]Node, error) {
	lx := NewLexer(r)

	ops := []Node{}
	for {
		token, pos, lit := lx.Next()
		if token == EOF { // stop at the end of the source
			break
		}
	}

	return ops, nil
}
```

Now is the real step of going ahead and parsing. Remember when I said:
> Any lone identifier is a command, and whatever after it are the arguments.
This makes it pluggable as is for our use in a terminal shell.

Which means that we can assume an IDENT token is a command, and for
simplicity we can expect 1 string afterwards to be the argument to it.
So we can have this in our loop:
```go
switch token {
	case IDENT:
		// if we're here then we're assuming this is a call
		node := Call{
			Pos: pos, // use the reported position from the token
			Name: lit, // And lit is what was tokenized as an identifier
		}

		// assume next token to be a string
		_, pos, lit := lx.Next()
		arg := Value{
			Pos: pos,
			Val: lit,
			Kind: StringKind,
		}
		node.Arguments = []Value{arg}
		ops = append(ops, node)
}
```

## Step 3: Interpreting
What good is a scripting language that can't be used to script!?
We need now need to run our code, based on the nodes that the AST gives
us.

So let's make a function to interpret our language:
```go
func Run(r io.Reader) {
	nodes, _ := Parse(r)

	for _, node := range nodes {
		// [...]
	}
}
```

Since the only AST node we have is just a Call, that's all we'll
check for, but it's still good to use a switch anyway to
add new cases.

So that gets added in our loop:
```go
// we can have a switch statement based on what concrete type
// we have because node is an interface!
switch n := node.(type) {
	case Call:
		// [...]
}
```

Hmm.. how are we going to have commands stored to call them?
First let's have a type for our commands:
```go
type Command func([]Value) // a command is passed a list of arguments
```

And then we can have a simple map to store them and at
the same time make a print function. We do this right before our parse loop.
```go
commands := make(map[string]Command)

commands["print"] = func(v []Value) {
	fmt.Println(v[0].Val)
}
```

Let's make our interpreter run this now.
```go
switch n := node.(type) {
	case Call:
		commandName := n.Name
		cmd := commands[commandName]

		cmd(n.Arguments)
}
```

Let's go back to our shell loop and remove our parseLine call and
the switch block under it, since we can just use our new Run function.
That leaves us with:
```go
for {
	line, err := rl.Readline()
	if err == io.EOF { // exit on ctrld
		break
	}

	fmt.Println(line)
	lx := NewLexer(strings.NewReader(line))

	for {
		token, pos, lit := lx.Next()
		if token == EOF {
			break
		}

		fmt.Printf("%d:%d %s %s\n", pos.Line, pos.Column, token, lit)
	}

	Run(strings.NewReader(line))
}
```

Now when we go to our shell and try to run that print command:
![](https://safe.kashima.moe/mjt7h4ulkg6h.png)
> It lives!

# Ending Off
This was honestly one of the most fun things I have made recently.
I like working on Hilbish and my other projects, but this was *exciting.*

I'll be working on making Asterscript more advanced for my use case,
like the math shown in the example at the beginning. Should it be based
on precedence? Whitespace-sensitive like Go, or just evaluate in order
with parentheses? Who knows.

You can check out more progress at my [PR] and my Discord server,
the "community" link at the top of this web page!

[Aster]: https://github.com/TorchedSammy/Aster
[Hilbish]: https://github.com/Rosettea/Hilbish
[PR]: https://github.com/TorchedSammy/Aster/pull/2
