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

## Nix Investigation

Nix is appealing to me because it

- Promises to be _both_ a package manager and a configuration manager
- Reliable by being a functional programming language

I have had good success with nix using it to cross compile the Linux kernel
and to natively compile Linux kernel version 5, which failed with gnu toolchain
version 11, and OpenSSLv3.

In general I want to use home-manager with flakes: <https://nix-community.github.io/home-manager/index.xhtml#ch-nix-flakes>

Because my repo is comprised of GNU Stow packages, a comprising home.nix
would look a bit strange with its source and target paths.

Here is what my home.nix looks like so far:

```nix
{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rsch";
  home.homeDirectory = "/home/rsch";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # neovim
    pkgs.neovim
    pkgs.git
    pkgs.fzf
    pkgs.zsh
    pkgs.qemu
    pkgs.stow
    pkgs.docker
    pkgs.gopls
    pkgs.ripgrep
    pkgs.hostname
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # nvim/.config structure is leftover from gnu stow
    "nvim".source = nvim/.config/nvim; # nvim/.config structure is leftover from gnu stow
    "nvim".recursive = true;
    # Target has home does not work, needs to be a specific folder
    # Also no two files can have the same target, even if its a directory
    # So target=.config will not work as other dotfiles needs that folder
    "nvim".target = ".config/nvim";
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/rsch/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
```

Another option is to devise a system where each folder has a install.sh
in the root, and it does the linking.

> [!IMPORTANT]
> Look into ways to keep home-manager modular, ideally I
> would like each of my stow packages (the folders in this repo)
> to have its corresponding nix file

## My new Keeb

Yeah I built a new keyboard and am pretty excited about it.

- KKT Kang White V3s - Lubed With 205g0. This took approximately 12 hours.
- Cerakey whites - Ceramic Keys. I think this is the essential piece
- Neo65
- Durock Screw In stabs with 205g0 and dialectic grease.

## A Note on the machine specific folders

Using `Tactitus` and `Melville` folders are not recommended for future me
as my stowing them will force stow to using individual symlinks per file
rather than directory wide. In other words

```sh
# before, was directory wide symlink
~/.config/git -> ~/dotfiles/git
# now became an individual symlink for each file (showing just one here)
~/.config/git/config -> ~/dotfiles/git/.config/git/config
```

[1]: https://www.reddit.com/r/linuxquestions/comments/kflzb3/a_noobs_guide_to_linux_ricing/
[2]: https://www.gnu.org/software/stow/manual/stow.html
[3]: https://www.lazyvim.org
