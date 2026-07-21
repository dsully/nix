---
paths: "**/*.{py,pyi}"
---

# Python

- Modern, Python 3.14+ - NEVER add deferred imports.
- Use TYPE_CHECKING only when necessary. DO NOT use it otherwise.
- Never use pip, always use uv.
- Always use type hints.
  - Do NOT use "Any" or "cast" or "ignore" unless absolutely necessary.
- Testing: Always use pytest style, no test classes. Re-usability via pytest fixtures.
  - Use pytest-datadir instead of manual data file construction.
  - Use pytest tmppath for temporary files.
