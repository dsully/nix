General
=======

* Do not add useless or obvious comments.
* When writing tests, use minimal mocking and only test things that add value.
* Do not write extraneous tests.
* Do not write summaries unless I ask.

Python
------

When, and only when writing Python code, use the following rules:

* Use built-in generic types introduced in PEP 585:
  + Use list instead of List
  + Use dict instead of Dict
  + Use set, tuple, etc., instead of Set, Tuple, etc.
* Use PEP 604 syntax for optional and union types:
  + Use str | None instead of Optional[str]
  + Use int | str instead of Union[int, str]
* Do not import List, Dict, Set, Tuple, Optional, or Union from the typing module.

* Always add return type hints.
* Assume Python 3.11+.
* Use contextlib.suppress if needed.
* Prefer the form: "from *package* import ..."
* For modeling, use pydantic instead of dataclasses.
* For date and time related code, always use the "whenever" module.
* Always use loguru and never the standard logging module.
* Always use pytest and function based testing. Use "uv run pytest" for running tests.
* Always use "uv" for dependency management. Never use pip.
* Always use "click" for command line parsing. Never use argparse.
* For toml, always use tomllib.
* Use itertools or more-itertools if appropriate.
* Always use httpx and never requests.
* Use "rich" and "rich.progress" if needed.
* Always run "ruff format" to format code.
* If building a web application, use FastAPI.

Rust
----

When, and only when writing Rust code, use the following rules:

* Always use the 2024 edition of Rust.

* Always use the latest version of crates. Use "cargo upgrade" if needed.

* Always use "jiff" instead of "chrono" for date and time needs.

* Always use clap derive if using clap.

* To check code, always use: "cargo clippy -- --no-deps"

* Never suppress or allow clippy issues. Fix the core problem instead.

* If using PyO3 for Rust/Python extension modules, always use "maturin develop" and not "cargo build".

Lua:

When, and only when writing Lua code, use the following rules:

* Always use Neovim APIs, such as vim. vim.nvim_
* Assume Neovim 0.11+ / nightly.
* Always use emmylua type annotations.
* Always run "stylua" to format code.
