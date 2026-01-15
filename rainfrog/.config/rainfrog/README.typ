= Double Symlink on macOS <sec:Double-Symlink-on-macOS>
Rainfrog wants `~/Library/Application\ Support/dev.rainfrog.rainfrog` on macOS.
What we want is
`~/Library/Application\ Support/dev.rainfrog.rainfrog -> ~/.config/rainfrog`
and `~/.config/rainfrog -> ~/dotfiles/rainfrog/.config/rainfrog`

We pretty much already know how to do this.

*Step 1*

Remove the old rainfrog in `~/Library/Application\ Support` if it exists.
`rm -rf ~/Application \Support/rainfrog`

*Step 2*

Do the first link.
`ln -s ~/.config/rainfrog ~/Library/Application\ Support/dev.rainfrog.rainfrog`

*Step 3*

_Note: Assume we have set up rainfrog like all of our XDG files:
`mkdir -p ~/dotfiles/rainfrog/.config/rainfrog`._


Do the second link:
`cd ~/dotfiles && stow rainfrog`


All done!



