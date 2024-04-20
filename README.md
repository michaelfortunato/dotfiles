# dotfiles

This repository holds my dear dotfiles

## Installation

I have a personality that is susceptible to endless ["ricing"][1].
In order to protect against this, the install needs to be as simple as possible

```bash
git clone github.com/michaelfortunato/dotfiles ~ \
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

## My new keeb

Yeah I built a new keyboard and am pretty excited about it.

- KKT Kang White V3s - Lubed With 205g0. This took approximately 12 hours.
- Cerakey whites - Ceramic Keys. I think this is the essential piece
- Neo65
- Durock Screw In stabs with 205g0 and dialectic grease.

[1]: https://www.reddit.com/r/linuxquestions/comments/kflzb3/a_noobs_guide_to_linux_ricing/
[2]: https://www.gnu.org/software/stow/manual/stow.html
[3]: https://www.lazyvim.org
