# Why is there a .python-version file here

As of now, you cannot easily set the default python version
that uv looks for. What uv does instead is look for a file called
.python-version in each parent directory that has the default which is so silly.
But we add this here. Just know that if you want to change the default
python version that uv looks for, edit `.python-version` here, which
is symlinked to `$HOME`
