# project-wrapper

A simple bash-CLI utility to easy access and setup projects around the
filesystem.

## What is this?

Are you like me, burying projects under deeply nested directories every damn
time, even though you have the memory of a goldfish? And are you also like me,
forgetting every single time to activate whatever environment setup the
language needs, like pyhton virtual environments or the right version of
node.js? Then, this may be what you've been looking for for ages!

The idea is pretty simple and straightforward: named projects associated to
a path in the filesystem, that can be *activated* by entering a terminal
command. Upon activation, the path is `cd`-ed into and the language-specific
environment setup are executed, if necessary.

## Table of contents

- [Features](#features)
    - [`pyenv` and `rbenv`](#shims)
- [Roadmap](#roadmap)
- [Installation](#installation)
- [Usage](#usage)
    - [`add-proj`](#add-proj)
    - [`del-proj`](#del-proj)
    - [`ls-proj`](#ls-proj)
    - [`new-proj`](#new-proj)
    - [`proj`](#proj)

## Features

- Name-path mapping to quick access directories across the filesystem.
- Autocompletion of project names when possible.
- Node.js version activation (requires `.nvmrc`):
    - Via [nvm](https://github.com/creationix/nvm).
    - Via [n](https://github.com/tj/n).
    - Via [my personal n fork](https://github.com/davla/n) (this is a
        personal project, after all 😉).
- Python virtual environments activation:
    - Via [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/en/latest/).
    - Via [venv](https://docs.python.org/3/library/venv.html)/[virtualenv](https://virtualenv.pypa.io/en/latest/).
- Ruby environment activation:
    - Via [rvm](https://rvm.io/).

### <a name="shims"></a> What about pyenv and rbenv?
Both [rbenv](https://github.com/rbenv/rbenv) and its python fork
[pyenv](https://github.com/pyenv/pyenv) do not need activation in the current
shell. This means that nothing needs to be done by this tool if you use them.

## Roadmap

- ~~Project names autocompletion~~.
- Build and installation.
- Auto-recognition of current active project.
- File-system deletion.
- Clear all entries.

## Installation

The build file that I still have to make

Why it is sourced should go here

## Usage

<a name="add-proj"></a>
The `add-proj` command adds/modifies a project to/in the mapping. It has the
following syntax:
```bash
add-proj PROJECT-NAME BASE-DIR
```
`BASE-DIR` can be an absolute path or relative to the current directory. The
`add-proj` command also `cd`s in `BASE-DIR`

<a name="del-proj"></a>
The `del-proj` command is used to delete a project from the mapping. It
supports autocompletion of project names. Its syntax is:
```bash
del-proj PROJECT-NAME
```

<a name="ls-proj"></a>
The `ls-proj` command displays the current mapping. It has the syntax:
```bash
ls-proj
```

<a name="new-proj"></a>
The `new-proj` command is just a shorthand for `add-proj` that also create the
project directory if it doesn't already exist. Its syntax is:
```bash
new-proj PROJECT-NAME BASE-DIR
```

<a name="proj"></a>
A project is *activated* via the `proj` command, that has the following syntax:
```bash
proj PROJECT-NAME
```
The `proj` command `cd`s into the directory mapped to `PROJECT-NAME`, if any,
and the proceeds to the activation of language-specific environment setup. It
also supports autocompletion of project names.
