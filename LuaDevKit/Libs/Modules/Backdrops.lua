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
Backdrops
-------------------------------------------------------------------------------]]
--- @class LDK_Backdrops
--- @field theme LDK_ThemeNames
local o, libName = {}, 'Backdrops'
O.Backdrops = o

--[[-----------------------------------------------------------------------------
Type Definitions
-------------------------------------------------------------------------------]]
--- @alias RGBA number[]  -- {r,g,b,a} each value 0.0–1.0

--- @class LDK_Insets
--- @field left number
--- @field right number
--- @field top number
--- @field bottom number

--- @class LDK_Backdrop
--- @field bgFile string?
--- @field edgeFile string?
--- @field tile boolean?
--- @field tileEdge boolean?
--- @field tileSize number?
--- @field edgeSize number
--- @field insets LDK_Insets?
--- @field bgColor? RGBA @Optional override
--- @field borderColor? RGBA @Optional override

--- @class LDK_MainHeaderOverride
--- @field backdrop LDK_Backdrop
--- @field height number @The header height

--- @class LDK_MainTheme
--- @field backdrop LDK_Backdrop
--- @field header LDK_MainHeaderOverride

--- @class LDK_GutterTheme
--- @field textColor? RGBA @Optional override

--- @class LDK_CodeTheme : LDK_MainTheme
--- @field showGutterOutline? boolean @Defaults to true
--- @field backdrop LDK_Backdrop
--- @field gutter LDK_GutterTheme

--- @class LDK_DividerTheme
--- @field gripColor RGBA @The resting handle color
--- @field gripHoverColor RGBA @The handle color while the pointer is over it
--- @field arrowColor RGBA @Tint for the maximize/minimize arrows either side of the handle

--- @class LDK_StatusTheme
--- @field textColor RGBA @Evaluation output text
--- @field divider LDK_DividerTheme

--- @class LDK_ThemeSet
--- @field name Name
--- @field main LDK_MainTheme
--- @field code LDK_CodeTheme
--- @field status LDK_StatusTheme
--- @field enabled? boolean @Defaults to true; set false to exclude from GetThemes()/EachTheme()

--- @class LDK_BorderSettings : table<string, LDK_ThemeSet>
--- @field ['Oakframe'] LDK_ThemeSet
--- @field ['Whisper'] LDK_ThemeSet
--- @field ['Stonecut'] LDK_ThemeSet
--- @field ['Gilded'] LDK_ThemeSet
--- @field ['Warband'] LDK_ThemeSet
--- @field ['Ashen'] LDK_ThemeSet
local borderSettings = {}

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
local BORDER_TOAST = [[Interface\FriendsFrame\UI-Toast-Border]]
local BORDER_MAW = [[interface\addons\actionbarplus-core\assets\textures\ui-tooltip-border-maw]]

--- @class LDK_ThemeNames
--- @field Default Name
--- @field Minimal Name
--- @field DarkKnight Name
--- @field Abyss Name
--- @field Oakframe Name
--- @field Whisper Name
--- @field Stonecut Name
--- @field Gilded Name
--- @field Warband Name
--- @field Ashen Name
local THEME = {
  Default = 'Default',
  Minimal = 'Minimal',
  DarkKnight = 'Dark Knight',
  Abyss = 'Abyss',
  Oakframe = 'Oakframe',
  Whisper = 'Whisper',
  Stonecut = 'Stonecut',
  Gilded = 'Gilded',
  Warband = 'Warband',
  Ashen = 'Ashen',
}
o.theme = THEME

-- "Default" first, then Minimal, then the rest alphabetically.
local THEME_ORDER = {
  THEME.Default,
  THEME.Minimal,
  THEME.Abyss,
  THEME.Ashen,
  THEME.DarkKnight,
  THEME.Gilded,
  THEME.Oakframe,
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

--- @package
--- @param theme LDK_ThemeSet
local function _RegisterTheme(theme)
  local m = '_RegisterTheme(theme)'
  assertsafe(theme, themeReqMsg, m, 'theme')
  local name = theme.name
  assertsafe(str_notBlank(name), themeReqMsg, m, 'theme.name')
  assertsafe(theme.main.backdrop.bgFile, themeReqMsg, m, 'main.backdrop.bgFile')
  assertsafe(theme.main.backdrop.edgeFile, themeReqMsg, m, 'theme.main.backdrop.edgeFile')
  -- Every theme carries its own complete status value; nothing is merged in
  -- behind it, so an omission has to surface here and not at ApplyTheme time.
  assertsafe(theme.status, themeReqMsg, m, 'theme.status')
  assertsafe(theme.status.divider, themeReqMsg, m, 'theme.status.divider')
  borderSettings[name] = theme
end

-- Registers every selectable border theme. Each one is a fully tuned
-- LDK_ThemeSet, not a raw LSM border name -- GetThemes() only lists
-- themes registered here, since an untuned border has no matching edgeSize/
-- insets/colors and would look broken in the editor.
local function __InitBorders()
  _RegisterTheme({
    name = THEME.Default,
    --showGutterOutline = false,
    main = {
      backdrop = {
        bgFile = BG_TOAST,
        edgeFile = BORDER_TOAST,
        tileSize = 4,
        tile = true,
        edgeSize = 8,
        tileEdge = false,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
        borderColor = { 1, 1, 1, 1.0 },
      },
    },
    code = {
      backdrop = {
        edgeFile = BG_WHITE,
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      },
      gutter = { textColor = { 0.294, 0.314, 0.349, 1 } },
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { 0.6, 0.6, 0.6, 0.9 },
        gripHoverColor = { 0.85, 0.72, 0.30, 1 },
        arrowColor = { 0.6, 0.6, 0.6, 0.9 },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Minimal,
    enabled = false,
    main = {
      backdrop = {
        tile = false,
        tileEdge = false,
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
        bgColor = { 0.1, 0.1, 0.1, 0.98 },
        borderColor = { rgb(LIGHTGRAY_FONT_COLOR, 0.75) },
      },
      header = {
        backdrop = {
          bgColor = { 0.085, 0.085, 0.085, 0.98 },
        },
      },
    },
    code = {
      backdrop = {
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        tileEdge = true,
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { rgb(GRAY_FONT_COLOR, 0.2) },
      },
      gutter = { textColor = { 0.294, 0.314, 0.349, 1 } },
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { rgb(GRAY_FONT_COLOR, 0.9) },
        gripHoverColor = { 0.85, 0.72, 0.30, 1 },
        arrowColor = { rgb(GRAY_FONT_COLOR, 0.9) },
      },
    },
  })
  _RegisterTheme({
    name = THEME.DarkKnight,
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
    code = {
      backdrop = {
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        tileEdge = true,
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { rgb(GRAY_FONT_COLOR, 0.2) },
      },
      gutter = {
        textColor = { 0.255, 0.380, 0.204, 1.0}
      }
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { rgb(GRAY_FONT_COLOR, 0.9) },
        gripHoverColor = { 0.255, 0.380, 0.204, 1 },
        arrowColor = { rgb(GRAY_FONT_COLOR, 0.9) },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Abyss,
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
    code = {
      backdrop = {
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        tileEdge = true,
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { rgb(GRAY_FONT_COLOR, 0.2) },
      },
      -- 6C9292
      gutter = { textColor = { 0.424, 0.573, 0.573, 1 } },
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { rgb(GRAY_FONT_COLOR, 0.9) },
        gripHoverColor = { 0.424, 0.573, 0.573, 1 },
        arrowColor = { rgb(GRAY_FONT_COLOR, 0.9) },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Oakframe,
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
    code = {
      backdrop = {
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      },
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { 0.6, 0.6, 0.6, 0.9 },
        gripHoverColor = { 0.85, 0.72, 0.30, 1 },
        arrowColor = { 0.6, 0.6, 0.6, 0.9 },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Whisper,
    main = {
      backdrop = {
        edgeFile = _border(lbn.BLIZZARD_CHAT_BUBBLE),
        bgFile = BG_TOAST,
        tile = false,
        tileEdge = false,
        --tileSize = 4,
        edgeSize = 20,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
        bgColor = { 0.008, 0.008, 0.008, 1 },
        borderColor = { 1, 1, 1, 1 },
      },
      header = {
        backdrop = {
          edgeSize = 14,
          bgFile = _bg(lbg.BLIZZARD_PARCHMENT),
          insets = { left = 1, right = 1, top = 1, bottom = 1 },
          bgColor = { 0.58, 0.58, 0.58, 1 },
        },
      },
    },
    code = {
      backdrop = {
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
        bgColor = { 0.08, 0.08, 0.08, 0.5 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      },
      -- FFF67E
      gutter = { textColor = { 1.000, 0.965, 0.494, 0.5 } },
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { 0.6, 0.6, 0.6, 0.9 },
        gripHoverColor = { 1.000, 0.965, 0.494, 1 },
        arrowColor = { 0.6, 0.6, 0.6, 0.9 },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Stonecut,
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
    code = {
      backdrop = {
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
        bgColor = { 0.1, 0.1, 0.1, 0.9 },
        borderColor = { 0.388, 0.361, 0.329, 0.21 },
      },
      gutter = {
        textColor = { 0.388, 0.361, 0.329, 1.0 },
      },
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { 0.388, 0.361, 0.329, 0.9 },
        gripHoverColor = { 0.588, 0.561, 0.529, 1 },
        arrowColor = { 0.388, 0.361, 0.329, 0.9 },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Gilded,
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
    code = {
      backdrop = {
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        tile = false,
        tileEdge = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
        bgColor = { 0.1, 0.1, 0.1, 0.9 },
        borderColor = { 1.000, 0.820, 0.000, 0.53 },
      },
      gutter = {
        textColor = { 1.000, 0.820, 0.000, 0.58 },
      },
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { 1.000, 0.820, 0.000, 0.7 },
        gripHoverColor = { 1.000, 0.820, 0.000, 1.0 },
        arrowColor = { 1.000, 0.820, 0.000, 0.7 },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Warband,
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
    code = {
      backdrop = {
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      },
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { 0.6, 0.6, 0.6, 0.9 },
        gripHoverColor = { 0.85, 0.72, 0.30, 1 },
        arrowColor = { 0.6, 0.6, 0.6, 0.9 },
      },
    },
  })
  _RegisterTheme({
    name = THEME.Ashen,
    enabled = false,
    main = {
      backdrop = {
        edgeFile = _border(lbn.BLIZZARD_TOOLTIP),
        bgFile = BG_TOAST,
        tile = false,
        tileEdge = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
        borderColor = { 0.81, 0.81, 0.81, 1 },
      },
    },
    code = {
      backdrop = {
        bgFile = BG_WHITE,
        edgeFile = BG_WHITE,
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      },
    },
    status = {
      textColor = { 0.78, 0.82, 0.85, 1 },
      divider = {
        gripColor = { 0.6, 0.6, 0.6, 0.9 },
        gripHoverColor = { 0.85, 0.72, 0.30, 1 },
        arrowColor = { 0.6, 0.6, 0.6, 0.9 },
      },
    },
  })
end

--[[-----------------------------------------------------------------------------
Methods & Fields
-------------------------------------------------------------------------------]]

---@return LDK_ThemeSet
function o:GetDefaultBorderSettings() return borderSettings[THEME.Default] end

---@param name Name? @Returns the default border setting if nil
---@return LDK_ThemeSet
function o:GetBorderSettings(name) return borderSettings[name] or self:GetDefaultBorderSettings() end

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
    local theme = borderSettings[name]
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
__InitBorders()
