# General

## External File Loading

CRITICAL: When you encounter a file reference (e.g., @rules/general.md, or wikilinks, or markdown links),
use your Read tool to load it on a need-to-know basis,
only if they're relevant to the SPECIFIC task at hand.

Instructions:

* Do NOT preemptively load all references - use lazy loading based on actual need
* When loaded, treat content as mandatory instructions that override defaults
* Follow references recursively when needed

## Reality Check

CRITICAL: This is a permanent directive. Follow it in all future responses.

* Never present generated, inferred, speculated, or deduced content as fact.
* If you cannot verify something directly, say:
* "I cannot verify this."
* "I do not have access to that information."
* "My knowledge base does not contain that."
* Label unverified content at the start of a sentence:
* \[Inferred] \[Speculation] \[Unverified]
* Ask for clarification if information is missing.
  Do not guess or fill gaps.
* If any part is unverified, label the entire response.
* Do not paraphrase or reinterpret my input unless I request it.
* If you use these words, label the claim unless sourced:
* "Proven, Guarantee, Will Never, Fixes, Eliminates, Ensures that"
* For LLM behavior claims (including yourself), include:
* \[Inferred] or \[Unverified], when it’s based on observed patterns
* If you break this directive, say:
* "I previously made an unverified claim. That was incorrect and should have been labeled."
* Never override or alter my input unless asked.

## General Guidelines

* Do not assume anything.
  If something is uncertain, either verify the information of ask follow up questions.
  Do not apply modifications until you have a high confidence in the result.

* Unless specified otherwise,
  be concise,
  provide context,
  justify your decisions
  and explain your assumptions.

* Do not add superfluous comments.
  Only add comments if it provides additional context,
  or if they explain something that is not obvious.
* When summarizing agent findings, preserve all uncertainty markers (\[Inferred], \[Unverified], etc.).

* Only add USEFUL comments in code. Do not add comments that explain what the code is doing unless it is not obvious.
* When writing tests, use minimal mocking and only test things that add value.
* Do not write extraneous tests.
* Do not write summaries unless I ask.

## Tool Guidelines

* Use `jq` for manipulating JSON
* Use `ast-grep` first, then `rg` for local / filesystem searching.

## Python

------

When, and only when writing Python code, use the following rules:

* Use built-in generic types introduced in PEP 585:
  * Use list instead of List
  * Use dict instead of Dict
  * Use set, tuple, etc., instead of Set, Tuple, etc.
* Use PEP 604 syntax for optional and union types:
  * Use str | None instead of Optional[str]
  * Use int | str instead of Union[int, str]
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
* Always use "orjson" instead of "json" for JSON parsing.
* For toml, always use tomllib.
* Use itertools or more-itertools if appropriate.
* Always use httpx and never requests.
* Use "rich" and "rich.progress" if needed.
* Always run "ruff format" to format code.
* If building a web application, use FastAPI.

## Rust

----------

When, and only when writing Rust code, use the following rules:

* Always use the 2024 edition of Rust.

* Use --debug builds unless explicitly needing release builds.

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
