# Tex Template

## Installation

Copy files from this folder

### Prerequisites

Make sure you have `just` and `pdflatex` installed.
You can get both and keep them up to date decently by doing

```sh
# somethign like nix profile install nixpkgs#texlive.combined.scheme-full
nix profile install nixpkgs#just
```

For tex, it'll be a few gigs, just live with it and get everything.

### Build

We use `just` as the build system. To build this file run
`just`. If you do not have just and do not want to install it,
adopt the just commands for your shell--they should be shell agnostic.

```sh
just
```
