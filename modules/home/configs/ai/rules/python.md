---
paths: "**/*.{py,pyi}"
---

# Python

- Python 3.14+. Imports at module top — never deferred. `TYPE_CHECKING` only
  when nothing else breaks the cycle.
- Tooling: `uv`, never pip. Type checker / LSP is `ty`, never pyright or
  basedpyright.
- Dataclasses or Pydantic — never NamedTuple or TypedDict.
- Prefer static/class methods over free functions.
- Vertical whitespace for readability; avoid temporary variables.
- Tests: pytest style, no test classes, reuse via fixtures. `pytest-datadir`
  for data files, `tmp_path` for temporaries.

## Type hints

The signature is the contract: what the caller reads, what the checker
enforces, and why a docstring never repeats a type.

- Annotate every parameter and return, `-> None` included. Never `self`/`cls`.
  Locals only where inference fails — empty containers, narrowed unions.
- Builtin generics (`list[str]`, `dict[str, int]`, `type[User]`), never
  `typing.List`/`Dict`/`Tuple`/`Type` and never `# type:` comments.
- `X | None` and `X | Y`, never `Optional`/`Union`. No implicit optional.
- Accept wide, return narrow: parameters take the `collections.abc` protocol
  covering what you actually do (`Iterable`, `Sequence`, `Mapping` when you only
  read, `MutableMapping` when you write); returns are concrete.
- No mutable defaults. Default to `None`, widen with `| None`, resolve in body.
- `Any` is not a shrug: `object` for genuinely opaque, a type parameter when the
  return follows an argument, a `Protocol` for a shape. A real `Any`, `cast`, or
  ignore comment earns one line saying why.
- PEP 695 generics and aliases: `def first[T](items: Sequence[T]) -> T:`,
  `type UserId = int`. Decorators preserve signatures with `ParamSpec`, not
  `Callable[..., Any]`.
- `@overload` when the return type varies across call forms rather than across
  one argument's type.

A signature that needs a comment to explain its types needs better types.

## Docstrings (Google style)

Write for the caller, who sees the signature and knows nothing about the
implementation or its history.

Required on public modules, classes, and functions. Skip private helpers,
self-explanatory one-liners, functions under ~3 lines with descriptive names,
and `__init__` that only assigns arguments.

- Summary: one imperative line ending in a period, then a blank line. Extended
  description only when it adds what the signature cannot.
- Never state types, never restate the function name
  (`"""Initialize the class."""`), never open with filler ("This function is
  used to...").
- The global comment rules apply: a docstring is not a changelog.
- Sections in order: `Args:` (meaning, not type; omit when there are no
  parameters), `Returns:` or `Yields:` (omit when returning `None`), `Raises:`
  (exceptions a caller should handle, and what triggers each).
