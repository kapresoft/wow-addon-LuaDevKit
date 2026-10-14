[![Release Build](https://github.com/kapresoft/wow-addon-LuaDevKit/actions/workflows/release-build.yml/badge.svg)](https://github.com/kapresoft/wow-addon-LuaDevKit/actions/workflows/release-build.yml)

# LuaDevKit :: Write, run, and inspect Lua without leaving Azeroth.
> ▶ A [World of Warcraft](https://worldofwarcraft.com/) AddOn

![download-count](https://cf.way2muchnoise.eu/full_1689187_downloads.svg?badge_style=for_the_badge) ![supported-wow-versions](https://cf.way2muchnoise.eu/versions/World%20of%20Warcraft%20Versions_1689187_all.svg?badge_style=for_the_badge)

An in-game Lua development toolkit for World of Warcraft addon authors. LuaDevKit gives you a line-numbered code editor, an output panel, and a one-line command prompt, so you can write, run, and debug Lua without leaving the game.

<img width="600" alt="image" src="https://github.com/user-attachments/assets/8ce7d458-3e7b-4742-93e0-bb04f061dbd9" />

## Who it's for

Addon developers who want a faster in-game workflow for writing, running, and debugging Lua snippets, without tabbing out to an external editor for quick iteration.

## Features

### Code Editor
- **Line-numbered editor**: a multi-line editing surface with a gutter that stays in sync with your code, with or without word wrap.
- **Run your code**: run the whole editor with the Run button or **Ctrl+1** (**Cmd+1** on Mac). Output and errors go to the output panel, not chat.
- **Documents**: keep multiple Lua documents. Create, save, rename, save as a copy, or delete them, and step through them with the arrow buttons. Optionally save each time you run.
- **Wrap Text**: toggle line wrapping; long lines either wrap or scroll sideways.
- **Resizable**: drag the dialog to the size you need.

### Output Panel and Command Line
- **Output panel**: docks below the code or to its right. Resize it, double-click its divider to maximize or minimize it, or clear it.
- **Command line**: run a single line of Lua and see its result right away. Step through earlier commands with the arrow keys or the history dropdown.
- **Editor helpers**: built-in functions for code in the editor and on the command line:

| Helper      | Description                          |
|-------------|--------------------------------------|
| `p(...)`    | Print to the output panel            |
| `t(...)`    | Trace to `/etrace`                   |
| `fm(value)` | Format a value across indented lines |
| `fs(value)` | Format a value on one line           |
| `fv(value)` | Show a table's keys and values as key=value pairs |
| `help()`    | Print this list                      |

```lua
local tbl = { hello = 'world', start = 1, stop = 10 }
p('tbl=', fm(tbl))
```

### Look and Feel
- **Themes**: 11 themes, including Abyss, Dark Knight, Gilded, Parchment, Slate, Stonecut, Warband, and the faction pair Job's Done (Alliance) and Zug Zug (Horde).
- **Monospace fonts**: pick a font family and size for the editor (sizes 10 to 28), with separate font settings for the output panel and command line. On Chinese and Korean clients, only fonts that can render the client's language are offered.
- **Help tour**: a guided tour of the main controls, shown in the editor.

### Settings
- Open the editor at startup, show or hide the toolbar, choose the output panel position, and make Escape close the editor. Without that option, the first Escape only leaves the text box.
- Settings are saved per profile. Managing profiles needs the LuaDevKit-Settings addon, which ships in the same package.

## Slash Commands

Each command works with either `/ldk` or `/luadevkit`.

| Command          | Description                    |
|------------------|--------------------------------|
| `/ldk editor`    | Toggles the Code Editor        |
| `/ldk settings`  | Toggles the settings window    |
| `/ldk info`      | Displays the addon info        |

## Requirements

- [SharedMediaFontsMono](https://www.curseforge.com/wow/addons/sharedmediafontsmono): provides the monospace fonts. The CurseForge app installs it automatically.

### Donations

If LuaDevKit has made your addon development easier, consider supporting its development:

- **[Paypal&trade; Donation](https://www.paypal.com/donate/?hosted_button_id=AX58YP3GSGXVU)**
- **[Bitcoin Donation](https://www.blockchain.com/btc/address/3QQVAwJGkKHMM2oq6CLVWYgfx83TFVwp39)**

## About

- About the Author [(Tony Lagnada)](https://tony.resume.lagnada.com/)
- My AddOn Portfolio Can Be Found Here [Curse Forge/Kapresoft](https://www.curseforge.com/members/kapresoft/projects)
