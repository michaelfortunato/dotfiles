# dotfiles

This repository holds my dear dotfiles

## Installation

I have a personality that is susceptible to endless ["ricing"][1].
In order to protect against this, the install needs to be as simple as possible

```sh
git clone --recurse-submodules --shallow-submodules https://github.com/michaelfortunato/dotfiles ~ \
  && stow nvim karabiner [etcetra]
```

## Maintaining

[GNU Stow][2] relies on the directory structure of config files to do its job.
Neovim files are stored under `~/.config/nvim`, so its directory structure is

```ascii
.
-- nvim
-- -- .config
-- -- -- nvim
-- -- -- -- init.lua
-- -- -- -- lua
-- -- -- -- -- [other lua files]

```

### How to migrate an existing folder in ~ to ~/dotfiles with Stow

1. `cp -r ~/<your-folder> ~/dotfiles/<stow-package>`
2. `rm -rf ~/<your-folder>`
3. `cd ~/dotfiles && stow <stow-package>`

Godspeed. And don't try to get fancy with `stow --adopt`, unless you can tell me
how to get it to work on folders.

### Git Submodule Technique

Do you know what I like about [LazyVim][3]?, it's update system does not rely
on git. That means that I can remove the .git directory and not maintain LazyVim
as a git submodule. Unfortunately, the same is not true for oh-my-zsh.

Fortunately, I think I have a pretty good system that allows me to declaratively
depend on the upstream version of oh-my-zsh. Here is what I did.

1. Delete the hard copy of `~/.oh-my-zsh`
2. git clone oh-my-zsh ~/dotfiles/zsh
3. `git submodule add <url> ~/dotfiles/zsh`

#### Updating Submodules

```bash
~ $ git submodule update --init --recursive --remote
```

You can also just go into each submodule and pull

## Which directories do what

### The `git` directory

Let us take a look at the structure here

```text
git
├── .git-commit-msg-schema.yaml
├── .git-commit-template
├── .git-hooks
│   ├── commit-msg
│   └── pre-push
├── .git-templates
│   └── default
└── .gitconfig
```

#### The `.git-hooks` directory

This directory consists of subdirectories, where each subdirectory is named after
a git hook type. As of 2024, the following exist, and so we could reasonably
populate the .git-hooks directory with them. So anytime I want to add a new git
hook, I should add it to one of the appropriate folders. Then later the
files will be sourced.

```text
applypatch-msg
pre-applypatch
post-applypatch
pre-commit
prepare-commit-msg
commit-msg
post-commit
pre-rebase
post-checkout
post-merge
pre-push
pre-receive
update
post-receive
post-update
reference-transaction
push-to-checkout
pre-auto-gc
post-rewrite
sendemail-validat
```

#### The `.git-templates` directory

This directory consists of subdirectories, where each subdirectory is a
[git-template](https://git-scm.com/docs/git-init#Documentation/git-init.txt-code--templatecodeemlttemplate-directorygtem).
The most important one is the `.git-templates/default` template. Which is
what every repository on my machine gets after a `git init`.

## My new keeb

Yeah I built a new keyboard and am pretty excited about it.

- KKT Kang White V3s - Lubed With 205g0. This took approximately 12 hours.
- Cerakey whites - Ceramic Keys. I think this is the essential piece
- Neo65
- Durock Screw In stabs with 205g0 and dialectic grease.

[1]: https://www.reddit.com/r/linuxquestions/comments/kflzb3/a_noobs_guide_to_linux_ricing/
[2]: https://www.gnu.org/software/stow/manual/stow.html
[3]: https://www.lazyvim.org
