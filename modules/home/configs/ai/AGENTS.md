# Reality Check

CRITICAL: This is a permanent directive. Follow it in all future responses.

- Never present generated, inferred, speculated, or deduced content as fact.
- Ask for clarification if information is missing.
- Do not guess or fill gaps.
- Do not paraphrase or reinterpret my input unless I request it.
- Never override or alter my input unless asked.
- NEVER fabricate information.
- ALWAYS keep these rules in your mind while working and
  don't let any information to be forgotten over time.
- IMPORTANT!!! You have access to MCP server tools to help you perform coding tasks.
- ALWAYS discover the tools available to you through MCP and use them as needed.
- You should use the web search tools or MCP instead of guessing answers.
- NEVER: git stash, git reset, git checkout, git restore

## Installed CLI tools

- **ast-grep** is installed — use for structural code searches and
  transformations on supported languages
- **fd** is installed — prefer over `find` for file finding by name/pattern
- **jq** is installed — use for JSON processing in shell pipelines
- **ripgrep** (`rg`) is installed — prefer over `grep` for shell searches
- **sd** is installed — prefer over `sed` for find-and-replace in files
- **yq** is installed — use for YAML processing in shell pipelines

## Comments

- Only add USEFUL comments in code. "Why" is more important than "what"
- Do not add comments that explain what the code is doing unless it is not obvious.

## Tests

- When writing tests, use minimal mocking and only write high value tests.
- Do not write extraneous tests. No junk tests. HIGH VALUE TESTS ONLY.
- Do not always "run tests" - run specific tests for items that you've changed.
- Test Driven Design: Ensure there is a failing test (red) first ideally.

## Style

- Clean, tight, readable, idiomatic code in the language. Do not be clever.
- No underscore functions, methods or variables.
- Whenever prompted to create a commit message, ALWAYS use conventional
  commit message format. BE VERY CONCISE, however you can include more
  details in the body of the commit message if necessary.

## Existing patterns

When implementing a new feature or workflow, first look for analogous
implementations and conventions in the codebase. Prefer matching nearby
or repo-wide patterns over introducing a new style, library, or structure.

## Editing

- ALWAYS read the file first before using your edit tools to do changes.
- NEVER overwrite the explicit changes that is done over your changes unless
  instructed to do so and ALWAYS analyze them first to take it as a guideline
  for coding standards.
- NEVER EVER PERFORM any operations that you can do with your internal tools
  through cli tools. DONT use `sed` for commands directly just use available
  editing tools, DONT use `cat` for writing scripts and similar.
- Prefer the filesystem MCP or treesitter MCP for these tasks.
- ALWAYS use git MCP server whenever needed instead of running the raw
  git commands whenever possible.
- Use treesitter MCP server for any kind of code structure analysis.

## Python

- Modern, Python 3.14+ - NEVER add deferred imports.
- Use TYPE_CHECKING only when necessary. DO NOT use it otherwise.
- Never use pip, always use uv.
- Always use type hints.
  - Do NOT use "Any" or "cast" or "ignore" unless absolutely necessary.
- Testing: Always use pytest style, no test classes. Reusability via pytest fixtures.
  - Use pytest-datadir instead of manual data file construction.
  - Use pytest tmppath for temporary files.

## Rust

- Always use 2024 Edition.
- Use cargo and crate mcps. Always use cargo to add or remove dependencies.
- Clippy pedantic is enabled by default.
