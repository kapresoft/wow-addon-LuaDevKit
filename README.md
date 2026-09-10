# LuaDevKit

An in-game Lua development toolkit for World of Warcraft addon authors. LuaDevKit gives you a line-numbered code editor, buffer evaluation, and variable inspection — all without leaving the game.

## Features

- **Line-numbered code editor** — a dedicated editing surface with a synced gutter, so line numbers always line up with your code, even when word-wrap is on.
- **Evaluate code** — run the contents of the editor buffer directly, the same way you'd use `/run` or a debug console, but with a proper multi-line editor instead of a single-line input.
- **Evaluate variables** — inspect the value of a variable or expression on demand, useful for quick debugging without littering your code with `print()` calls.
- **Configurable fonts** — switch between monospace fonts (Ubuntu Mono, JetBrains Mono, Source Code Pro) and font sizes (10/12/14) from in-dialog dropdowns.
- **Wrap or no-wrap modes** — toggle line wrapping; the gutter stays correctly numbered either way.
- **Resizable dialog** — drag to resize the editor to the space you need.

## Who it's for

Addon developers who want a faster, more comfortable in-game workflow for writing, running, and debugging small snippets of Lua — without tabbing out to an external editor for quick iteration.

## Notes

LuaDevKit is designed to be embedded by other addons as a lightweight library, with no dependency on a settings framework — the host addon owns persistence and just calls a small `Configure`/`SetOnConfigChanged` API to read and write settings.
