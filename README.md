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

## My new keeb

Yeah I built a new keyboard and am pretty excited about it.

- KKT Kang White V3s - Lubed With 205g0. This took approximately 12 hours.
- Cerakey whites - Ceramic Keys. I think this is the essential piece
- Neo65
- Durock Screw In stabs with 205g0 and dialectic grease.

[1]: https://www.reddit.com/r/linuxquestions/comments/kflzb3/a_noobs_guide_to_linux_ricing/
[2]: https://www.gnu.org/software/stow/manual/stow.html
