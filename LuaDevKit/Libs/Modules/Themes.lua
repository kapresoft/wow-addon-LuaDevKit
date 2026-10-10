--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local lsm = O.LSM
local mt, String, Table = lsm.MediaType, O.String, O.Table
local str_eq, str_empty = String.EqualsIgnoreCase, String.IsEmpty
local str_notBlank = String.IsNotBlank
local tbl_deepCopy = Table.DeepCopy
local tbl_Merge = Table.MergeRecursive

local themeReqMsg = '%s: %s is required'
local nameReqMsg = '%s: %s should be a string.'

--[[-----------------------------------------------------------------------------
Themes
-------------------------------------------------------------------------------]]
--- @class LDK_Themes
--- @field theme LDK_ThemeNames
local o, libName = {}, 'Themes'
O.Themes = o

--[[-----------------------------------------------------------------------------
Type Definitions
-------------------------------------------------------------------------------]]
--- @alias RGBA number[]  -- {r,g,b,a} each value 0.0–1.0
--- @alias RGB number[]   -- {r,g,b} each value 0.0–1.0

--- @class LDK_Insets
--- @field left number
--- @field right number
--- @field top number
--- @field bottom number

--- @class LDK_Backdrop
--- @field bgFile? string
--- @field edgeFile? string
--- @field tile? boolean
--- @field tileEdge? boolean
--- @field tileSize? number
--- @field edgeSize number
--- @field insets? LDK_Insets
--- @field bgColor? RGBA
--- @field borderColor? RGBA

--- @class LDK_MainHeaderOverride
--- @field backdrop? LDK_Backdrop @Merged over main.backdrop
--- @field height? number         @Defaults to the dialog's HEADER_HEIGHT
--- @field iconColor? RGBA        @Tint for the header's white glyph icons; defaults to palette.base

--- @class LDK_MainTheme
--- @field backdrop LDK_Backdrop
--- @field header? LDK_MainHeaderOverride
--- @field labelColor? RGBA @Text on the main background, e.g. Wrap Text; defaults to gold

--- @class LDK_GutterTheme
--- @field textColor? RGBA @Defaults to palette.base

--- @class LDK_PanelTheme
--- @field backdrop LDK_Backdrop @Gutter, code, output and command line boxes; borderColor defaults to palette.base

--- Hex 'RRGGBB' per Lua token kind; logical is and/or/not.
--- @class LDK_SyntaxColors
--- @field keyword? string
--- @field string? string
--- @field number? string
--- @field comment? string
--- @field identifier? string
--- @field logical? string

--- @class LDK_FontSteppersTheme
--- @field color? RGBA   @Tint for the gold +/- art; only darkens it; defaults to none
--- @field alpha? number @Resting alpha; defaults to the other code-area buttons'

--- @class LDK_CodeTheme
--- @field gutter? LDK_GutterTheme
--- @field fontSteppers? LDK_FontSteppersTheme
--- @field textColor? RGBA           @Operators and other uncolored code; defaults to white
--- @field syntax? LDK_SyntaxColors @Merged over the dark-background defaults

--- @class LDK_DividerTheme
--- @field gripColor? RGBA      @The resting handle color; defaults to palette.base
--- @field gripHoverColor? RGBA @The handle color while the pointer is over it; defaults to palette.base
--- @field arrowColor? RGBA     @Tint for the maximize/minimize arrows; defaults to palette.base

--- @class LDK_XY
--- @field x number
--- @field y number

--- @class LDK_ToolIconsTheme
--- @field inset? LDK_XY @The icon row's corner, in from the output panel's top right
--- @field alpha? number @Resting alpha of every output tool icon; hover stays full

--- @class LDK_OutputTheme
--- @field textColor RGBA   @Evaluation output text
--- @field printColor? RGBA @print() output; defaults to gray
--- @field errorColor? RGBA @Compile and runtime errors; defaults to red
--- @field toolIcons? LDK_ToolIconsTheme

--- @class LDK_PromptTheme
--- @field color? RGBA    @Defaults to the command line's textColor
--- @field offset? LDK_XY @From the command line's left; y up

--- @class LDK_CommandLineTheme
--- @field textColor? RGBA @Typed text; defaults to output.textColor
--- @field prompt? LDK_PromptTheme

--- @class LDK_ConsoleTheme
--- @field output LDK_OutputTheme
--- @field commandLine? LDK_CommandLineTheme
--- @field divider? LDK_DividerTheme

--- @class LDK_PaletteTheme
--- @field base? RGB @Accent hue; colors a theme leaves out are tinted from it

--- @class LDK_ThemeSet
--- @field name Name
--- @field palette? LDK_PaletteTheme
--- @field main LDK_MainTheme
--- @field panel LDK_PanelTheme
--- @field code? LDK_CodeTheme
--- @field console LDK_ConsoleTheme
--- @field enabled? boolean @Defaults to true; set false to exclude from GetThemes()/EachTheme()
--- @field default? boolean @The theme a new editor starts with; first enabled one wins

--- @class LDK_ThemeRegistry : table<string, LDK_ThemeSet>
--- @field ['Abyss'] LDK_ThemeSet
--- @field ['Dark Knight'] LDK_ThemeSet
--- @field ['Gilded'] LDK_ThemeSet
--- @field ['Oakframe'] LDK_ThemeSet
--- @field ['Parchment'] LDK_ThemeSet
--- @field ['Stonecut'] LDK_ThemeSet
--- @field ['Warband'] LDK_ThemeSet
--- @field ['Whisper'] LDK_ThemeSet
local themes = {}

--- @see LibSharedMedia-3.0
local LSM_BACKGROUND_NAMES = {
  BLIZZARD_COLLECTIONS_BACKGROUND = 'Blizzard Collections Background',
  BLIZZARD_DIALOG_BACKGROUND = 'Blizzard Dialog Background',
  BLIZZARD_DIALOG_BACKGROUND_DARK = 'Blizzard Dialog Background Dark',
  BLIZZARD_DIALOG_BACKGROUND_GOLD = 'Blizzard Dialog Background Gold',
  BLIZZARD_GARRISON_BACKGROUND = 'Blizzard Garrison Background',
  BLIZZARD_GARRISON_BACKGROUND_2 = 'Blizzard Garrison Background 2',
  BLIZZARD_GARRISON_BACKGROUND_3 = 'Blizzard Garrison Background 3',
  BLIZZARD_LOW_HEALTH = 'Blizzard Low Health',
  BLIZZARD_MARBLE = 'Blizzard Marble',
  BLIZZARD_OUT_OF_CONTROL = 'Blizzard Out of Control',
  BLIZZARD_PARCHMENT = 'Blizzard Parchment',
  BLIZZARD_PARCHMENT_2 = 'Blizzard Parchment 2',
  BLIZZARD_ROCK = 'Blizzard Rock',
  BLIZZARD_TABARD_BACKGROUND = 'Blizzard Tabard Background',
  BLIZZARD_TOOLTIP = 'Blizzard Tooltip',
  SOLID = 'Solid',
}
local lbg = LSM_BACKGROUND_NAMES

--- @see LibSharedMedia-3.0
local LSM_BLIZZ_NAMES = {
  BLIZZARD_ACHIEVEMENT_WOOD = 'Blizzard Achievement Wood',
  BLIZZARD_CHAT_BUBBLE = 'Blizzard Chat Bubble',
  BLIZZARD_DIALOG = 'Blizzard Dialog',
  BLIZZARD_DIALOG_GOLD = 'Blizzard Dialog Gold',
  BLIZZARD_PARTY = 'Blizzard Party',
  BLIZZARD_TOOLTIP = 'Blizzard Tooltip',
}
local lbn = LSM_BLIZZ_NAMES
local BG_TOAST = [[Interface\FriendsFrame\UI-Toast-Background]]
local BG_WHITE = [[interface\buttons\white8x8]]
local BORDER_MAW = [[interface\addons\luadevkit\assets\ui-tooltip-border-maw]]

local INSETS_NONE = { left = 0, right = 0, top = 0, bottom = 0 }
local INSETS_PAD = { left = 3, right = 3, top = 4, bottom = 3 }

-- Tuned for dark code backgrounds; light themes override them.
--- @type LDK_SyntaxColors
local DEFAULT_SYNTAX = {
  keyword = 'CF8E6D',
  string = 'EFEFEF',
  number = '2AACB8',
  comment = '9B9EA5',
  identifier = '56B2FF',
  logical = 'FFB9B0',
}
local DEFAULT_CODE_TEXT_COLOR = { 1, 1, 1, 1 }
local DEFAULT_PRINT_COLOR = { 0.6, 0.6, 0.6, 1 }
local DEFAULT_ERROR_COLOR = { 1, 0, 0, 1 }

--- @class LDK_ThemeNames
--- @field DarkKnight Name
--- @field Abyss Name
--- @field Oakframe Name
--- @field Parchment Name
--- @field Whisper Name
--- @field Stonecut Name
--- @field Gilded Name
--- @field Warband Name
local THEME = {
  DarkKnight = 'Dark Knight',
  Abyss = 'Abyss',
  Oakframe = 'Oakframe',
  Parchment = 'Parchment',
  Whisper = 'Whisper',
  Stonecut = 'Stonecut',
  Gilded = 'Gilded',
  Warband = 'Warband',
}
o.theme = THEME

-- Alphabetical.
local THEME_ORDER = {
  THEME.Abyss,
  THEME.DarkKnight,
  THEME.Gilded,
  THEME.Oakframe,
  THEME.Parchment,
  THEME.Stonecut,
  THEME.Warband,
  THEME.Whisper,
}

--[[-----------------------------------------------------------------------------
Custom Backdrops
-------------------------------------------------------------------------------]]
--- @param p any
--- @return boolean
local function is_tbl(p) return type(p) == 'table' end

--- @param color colorRGBA
--- @param a alpha
--- @return number, number, number, alpha @Red, Green, Blue
local function rgb(color, a) return color.r, color.g, color.b, a end

--- @param color colorRGBA
--- @return number, number, number, alpha @Red, Green, Blue, Alpha
local function rgba(color)
  return color.r, color.g, color.b, color.a --[[@as alpha ]]
end

--- Default accept function
--- @return true
local function acceptAll() return true end

--- @param name Name
--- @return string?
--- @private
local function _bg(name)
  assertsafe(str_notBlank(name), nameReqMsg, '_bg(name)', 'name')
  return lsm:Fetch(mt.BACKGROUND, name, true)
end

--- @private
--- @param name Name
--- @return string?
local function _border(name)
  assertsafe(str_notBlank(name), nameReqMsg, '_border(name)', 'name')
  return lsm:Fetch(mt.BORDER, name, true)
end

--- 1px solid-edge backdrop for the code, gutter and console panels.
--- @param spec { insets?: LDK_Insets, bgColor?: RGBA, borderColor?: RGBA }
--- @return LDK_Backdrop
local function _panel(spec)
  return {
    bgFile = BG_WHITE,
    edgeFile = BG_WHITE,
    edgeSize = 1,
    tileSize = 4,
    insets = spec.insets,
    bgColor = spec.bgColor,
    borderColor = spec.borderColor,
  }
end

-- Alpha of each palette.base tint, per role.
local PALETTE_ALPHA = {
  panelBorder = 0.53,
  gutterText = 0.58,
  grip = 0.7,
  gripHover = 1.0,
  arrow = 0.99,
  headerIcon = 0.99,
}

--- @param base RGB
--- @param alpha number
--- @return RGBA
local function _tint(base, alpha) return { base[1], base[2], base[3], alpha } end

--- Fills colors a theme leaves out with palette.base tints.
--- @param t LDK_ThemeSet @A copy; filled in place
local function _ResolvePalette(t)
  local base = t.palette and t.palette.base
  if not base then return end
  local pbd = t.panel.backdrop
  pbd.borderColor = pbd.borderColor or _tint(base, PALETTE_ALPHA.panelBorder)
  t.code = t.code or {}
  t.code.gutter = t.code.gutter or {}
  local gutter = t.code.gutter
  gutter.textColor = gutter.textColor or _tint(base, PALETTE_ALPHA.gutterText)
  t.console.divider = t.console.divider or {}
  local divider = t.console.divider
  divider.gripColor = divider.gripColor or _tint(base, PALETTE_ALPHA.grip)
  divider.gripHoverColor = divider.gripHoverColor or _tint(base, PALETTE_ALPHA.gripHover)
  divider.arrowColor = divider.arrowColor or _tint(base, PALETTE_ALPHA.arrow)
  t.main.header = t.main.header or {}
  local header = t.main.header
  header.iconColor = header.iconColor or _tint(base, PALETTE_ALPHA.headerIcon)
end

--- Fills the code text and syntax colors a theme leaves out.
--- @param t LDK_ThemeSet @A copy; filled in place
local function _ResolveCode(t)
  t.code = t.code or {}
  local code = t.code
  code.textColor = code.textColor or DEFAULT_CODE_TEXT_COLOR
  code.syntax = tbl_Merge(DEFAULT_SYNTAX, code.syntax or {})
end

--- Fills the print and error colors a theme leaves out.
--- @param t LDK_ThemeSet @A copy; filled in place
local function _ResolveOutput(t)
  local output = t.console.output
  output.printColor = output.printColor or DEFAULT_PRINT_COLOR
  output.errorColor = output.errorColor or DEFAULT_ERROR_COLOR
end

--- @package
--- @param theme LDK_ThemeSet
local function _RegisterTheme(theme)
  local m = '_RegisterTheme(theme)'
  assertsafe(theme, themeReqMsg, m, 'theme')
  local name = theme.name
  assertsafe(str_notBlank(name), themeReqMsg, m, 'theme.name')
  assertsafe(theme.main.backdrop.bgFile, themeReqMsg, m, 'main.backdrop.bgFile')
  assertsafe(theme.main.backdrop.edgeFile, themeReqMsg, m, 'theme.main.backdrop.edgeFile')
  -- A missing value, or a color with no palette.base to tint it from,
  -- has to surface here and not at ApplyTheme time.
  assertsafe(theme.panel, themeReqMsg, m, 'theme.panel')
  assertsafe(theme.panel.backdrop, themeReqMsg, m, 'theme.panel.backdrop')
  assertsafe(theme.console, themeReqMsg, m, 'theme.console')
  assertsafe(theme.console.output, themeReqMsg, m, 'theme.console.output')
  local base = theme.palette and theme.palette.base
  local divider = theme.console.divider or {}
  for _, key in ipairs({ 'gripColor', 'gripHoverColor', 'arrowColor' }) do
    assertsafe(
      divider[key] or base,
      themeReqMsg,
      m,
      'theme.console.divider.' .. key .. ' or theme.palette.base'
    )
  end
  local header = theme.main.header or {}
  assertsafe(
    header.iconColor or base,
    themeReqMsg,
    m,
    'theme.main.header.iconColor or theme.palette.base'
  )
  themes[name] = theme
end

-- Registers every selectable border theme. Each one is a fully tuned
-- LDK_ThemeSet, not a raw LSM border name -- GetThemes() only lists
-- themes registered here, since an untuned border has no matching edgeSize/
-- insets/colors and would look broken in the editor.
local function _RegisterBuiltInThemes()
  _RegisterTheme({
    name = THEME.DarkKnight,
    default = true,
    palette = { base = { 0.255, 0.380, 0.204 } },
    main = {
      backdrop = {
        bgFile = BG_TOAST,
        edgeFile = _border(lbn.BLIZZARD_TOOLTIP),
        tile = false,
        tileEdge = false,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
        bgColor = { 0, 0, 0, 0.95 },
        borderColor = { 0.53, 0.53, 0.53, 1 },
      },
      header = {
        backdrop = {
          bgFile = _bg(lbg.BLIZZARD_PARCHMENT),
          bgColor = { 0.12, 0.12, 0.12, 1.0 },
        },
      },
    },
    panel = {
      backdrop = _panel({
        insets = INSETS_PAD,
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { rgb(GRAY_FONT_COLOR, 0.2) },
      }),
    },
    console = {
      output = {
        textColor = { 0.78, 0.82, 0.85, 1 },
      },
      commandLine = {
        prompt = {
          color = { 0.3, 0.5, 0.3, 1.0 },
          offset = { x = 5, y = 0 },
        },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Abyss,
    palette = { base = { 0.424, 0.573, 0.573 } },
    main = {
      backdrop = {
        bgFile = BG_TOAST,
        edgeFile = BORDER_MAW,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
        borderColor = { 1, 1, 1, 1.0 },
      },
      header = {
        backdrop = {
          bgFile = _bg(lbg.BLIZZARD_TABARD_BACKGROUND),
          tile = false,
          tileEdge = false,
          edgeSize = 16,
          bgColor = { 1, 1, 1, 0.8 },
        },
      },
    },
    panel = {
      backdrop = _panel({
        insets = INSETS_PAD,
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { rgb(GRAY_FONT_COLOR, 0.2) },
      }),
    },
    console = {
      output = {
        textColor = { 0.78, 0.82, 0.85, 1 },
        toolIcons = { inset = { x = 3, y = 4 } },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Oakframe,
    palette = { base = { 0.85, 0.72, 0.30 } },
    main = {
      backdrop = {
        edgeFile = _border(lbn.BLIZZARD_ACHIEVEMENT_WOOD),
        bgFile = BG_TOAST,
        tile = false,
        tileEdge = false,
        edgeSize = 24,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
        borderColor = { 1, 1, 1, 1.0 },
      },
      header = {
        backdrop = {
          bgFile = _bg(lbg.BLIZZARD_GARRISON_BACKGROUND),
          tile = false,
          tileEdge = false,
          edgeSize = 20,
          bgColor = { 1, 1, 1, 1.0 },
        },
        height = 30,
      },
    },
    panel = {
      backdrop = _panel({
        insets = INSETS_PAD,
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      }),
    },
    console = {
      output = {
        textColor = { 0.78, 0.82, 0.85, 1 },
        toolIcons = { inset = { x = 9, y = 4 } },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Whisper,
    palette = { base = { 1.000, 0.965, 0.494 } },
    main = {
      backdrop = {
        edgeFile = _border(lbn.BLIZZARD_CHAT_BUBBLE),
        bgFile = BG_TOAST,
        tile = false,
        tileEdge = false,
        edgeSize = 24,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
        bgColor = { 0.008, 0.008, 0.008, 1 },
        borderColor = { 1, 1, 1, 1 },
      },
      header = {
        backdrop = {
          edgeSize = 14,
          bgFile = _bg(lbg.BLIZZARD_PARCHMENT),
          insets = { left = 4, right = 4, top = 4, bottom = 4 },
          bgColor = { 0.58, 0.58, 0.58, 1 },
        },
      },
    },
    panel = {
      backdrop = _panel({
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
        bgColor = { 0.08, 0.08, 0.08, 0.5 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      }),
    },
    console = {
      output = {
        textColor = { 0.78, 0.82, 0.85, 1 },
        toolIcons = { inset = { x = 24, y = 4 } },
      },
      commandLine = {
        prompt = {
          color = { 0.435, 0.306, 0.216, 1 },
          offset = { x = 26, y = 0 },
        },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Stonecut,
    palette = { base = { 0.588, 0.561, 0.529 } },
    main = {
      backdrop = {
        edgeFile = _border(lbn.BLIZZARD_DIALOG),
        bgFile = BG_TOAST,
        tile = false,
        tileEdge = false,
        edgeSize = 24,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
        bgColor = { 0.85, 0.85, 0.88, 1.0 },
        borderColor = { 1, 1, 1, 1.0 },
      },
      header = {
        backdrop = {
          bgFile = _bg(lbg.BLIZZARD_COLLECTIONS_BACKGROUND),
        },
        height = 35,
      },
    },
    panel = {
      backdrop = _panel({
        insets = INSETS_NONE,
        bgColor = { 0.1, 0.1, 0.1, 0.9 },
        borderColor = { 0.388, 0.361, 0.329, 0.21 },
      }),
    },
    console = {
      output = {
        textColor = { 0.78, 0.82, 0.85, 1 },
        toolIcons = { inset = { x = 8, y = 4 } },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Gilded,
    palette = { base = { 1.000, 0.820, 0.000 } },
    main = {
      backdrop = {
        edgeFile = _border(lbn.BLIZZARD_DIALOG_GOLD),
        bgFile = _bg(lbg.BLIZZARD_DIALOG_BACKGROUND_GOLD),
        tile = false,
        tileEdge = false,
        tileSize = 12,
        edgeSize = 24,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
        bgColor = { 1, 1, 1, 1.0 },
        borderColor = { 1, 1, 1, 1.0 },
      },
      header = {
        backdrop = {
          bgFile = _bg(lbg.BLIZZARD_GARRISON_BACKGROUND_3),
          bgColor = { 1, 1, 1, 0.8 },
        },
        height = 35,
      },
    },
    panel = {
      backdrop = _panel({
        insets = INSETS_NONE,
        bgColor = { 0.1, 0.1, 0.1, 0.9 },
      }),
    },
    console = {
      output = {
        textColor = { 0.78, 0.82, 0.85, 1 },
      },
      commandLine = {
        prompt = {
          color = { 1.000, 0.671, 0.145, 1 },
        },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Warband,
    palette = { base = { 0.85, 0.72, 0.30 } },
    main = {
      backdrop = {
        edgeFile = _border(lbn.BLIZZARD_PARTY),
        bgFile = BG_TOAST,
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 6,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
      },
    },
    panel = {
      backdrop = _panel({
        insets = INSETS_PAD,
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      }),
    },
    console = {
      output = {
        textColor = { 0.78, 0.82, 0.85, 1 },
        toolIcons = { inset = { x = 4, y = 4 } },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Parchment,
    palette = { base = { 0.36, 0.25, 0.13 } },
    main = {
      backdrop = {
        bgFile = _bg(lbg.BLIZZARD_PARCHMENT),
        edgeFile = _border(lbn.BLIZZARD_TOOLTIP),
        tile = false,
        tileEdge = false,
        tileSize = 1,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
        bgColor = { 1, 1, 1, 1 },
        borderColor = { 0.45, 0.33, 0.2, 1 },
      },
      header = {
        backdrop = {
          bgFile = _bg(lbg.BLIZZARD_PARCHMENT),
          bgColor = { 0.4, 0.28, 0.16, 1 },
        },
        iconColor = { 1, 0.9, 0.7, 1 },
      },
      labelColor = { 0.25, 0.17, 0.1, 1 },
    },
    panel = {
      backdrop = _panel({
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
        bgColor = { 1, 0.98, 0.9, 0.35 },
      }),
    },
    code = {
      gutter = { textColor = { 0.192, 0.075, 0.012, 1 } },
      fontSteppers = { color = { 0.45, 0.3, 0.12, 1 }, alpha = 0.9 },
      textColor = { 0.17, 0.12, 0.08, 1 },
      syntax = {
        keyword = '9B2C0A',
        string = '2D6A1E',
        number = '1747C4',
        comment = '857560',
        identifier = '1F5F7A',
        logical = '8E2F7A',
      },
    },
    console = {
      output = {
        textColor = { 1.000, 0.965, 0.494, 1 },
        printColor = { 0.278, 0.224, 0.173, 1 },
        errorColor = { 0.7, 0.1, 0.05, 1 },
      },
      commandLine = {
        prompt = {
          color = { 0.45, 0.3, 0.1, 1 },
        },
      },
    },
  })
end

--[[-----------------------------------------------------------------------------
Methods & Fields
-------------------------------------------------------------------------------]]

---@return LDK_ThemeSet
function o:GetDefaultTheme() return themes[self:GetDefaultThemeName()] end

--- @return Name? @First enabled theme if none sets default; nil if none are enabled
function o:GetDefaultThemeName()
  local names = self:GetThemes()
  for _, name in ipairs(names) do
    if themes[name].default then return name end
  end
  return names[1]
end

---@param name Name? @Returns the default theme if nil
---@return LDK_ThemeSet @A copy with palette tints, code and output colors filled in
function o:GetTheme(name)
  local t = tbl_deepCopy(themes[name] or self:GetDefaultTheme()) --[[@as LDK_ThemeSet]]
  _ResolvePalette(t)
  _ResolveCode(t)
  _ResolveOutput(t)
  return t
end

--- For code shown on dark tooltips, whatever the theme.
--- @return LDK_SyntaxColors
function o:GetDefaultSyntax() return DEFAULT_SYNTAX end

--- @param theme LDK_ThemeSet @Returns the default border setting if nil
--- @return LDK_MainHeaderOverride?
function o:GetHeaderBackdropOverride(theme)
  assertsafe(is_tbl(theme), 'GetHeaderBackdropOverride(theme): Invalid theme: %s', tostring(theme))
  if not (theme and theme.main and theme.main.backdrop and theme.main.header) then return nil end

  local bd, header = theme.main.backdrop, theme.main.header
  --- @type LDK_MainHeaderOverride
  local hov = tbl_deepCopy(header)
  --- @type LDK_Backdrop
  hov.backdrop = tbl_Merge(bd, hov.backdrop)
  return hov
end

--- This is a custom ordered theme name list, excluding themes with enabled = false
--- @return string[]
function o:GetThemes()
  local names = {}
  for _, name in ipairs(THEME_ORDER) do
    local theme = themes[name]
    if theme and theme.enabled ~= false then names[#names + 1] = name end
  end
  return names
end

--- @param callbackFn fun(name:string)
--- @param acceptFilterFn? fun(name:string) : boolean @Return true to accept (include) a theme; defaults to accepting all
function o:EachTheme(callbackFn, acceptFilterFn)
  if not callbackFn then return end
  local fn = acceptFilterFn or acceptAll
  for _, name in ipairs(self:GetThemes()) do
    if fn(name) then callbackFn(name) end
  end
end

--[[-----------------------------------------------------------------------------
Last
-------------------------------------------------------------------------------]]
_RegisterBuiltInThemes()
