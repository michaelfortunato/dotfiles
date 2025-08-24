= Rust Jupyter Notebook In Neovim <sec:Rust-Jupyter-Notebook-In-Neovim>

+ Copy this folder to an empty folder, then run `uv venv`.
+ Next, run `source .venv/bin/activate`
+ Next, run `uv pip install pynvim jupyter`
+ Next, run `cargo install --locked evcxr_jupyter`
+ Next, run
  `env JUPYTER_PATH=$VIRTUAL_ENV/share/jupyter/ evcxr_jupyter --install`.
+ Next, add dependencies to the `Cargo.toml` file.
+ Next, add
```{rust}
Code ...
```

== Troubleshooting Tips <subsec:Troubleshooting-Tips>

- Run `:UpdateRemotePlugins` if Molten.nvim is complaining.
- Run `:OtterActive` if you are having trouble with `rust-analyzer`.
- Note, rust-analyzer will go out intermittently--maybe one day it'll get
  better.


