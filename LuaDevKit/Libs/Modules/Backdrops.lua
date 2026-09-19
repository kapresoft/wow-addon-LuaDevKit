--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local lsm = O.LSM
local mt, String, Table = lsm.MediaType, O.String, O.Table
local str_eq, str_empty = String.EqualsIgnoreCase, String.IsEmpty
local str_notBlank = String.IsNotBlank
local tbl_deepCopy = Table.DeepCopy
local tbl_Merge = Table.MergeRecursive

--[[-----------------------------------------------------------------------------
Backdrops
-------------------------------------------------------------------------------]]
--- @class LDK_Backdrops
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

--- @class LDK_CodeTheme : LDK_MainTheme
--- @field showGutterOutline? boolean @Defaults to true
--- @field backdrop LDK_Backdrop

--- @class LDK_ThemeSet
--- @field name Name
--- @field label? Name @Display name override for menus; defaults to name
--- @field main LDK_MainTheme
--- @field code LDK_CodeTheme

--- @class LDK_BorderSettings : table<string, LDK_ThemeSet>
--- @field ['Blizzard Achievement Wood'] LDK_ThemeSet
--- @field ['Blizzard Chat Bubble'] LDK_ThemeSet
--- @field ['Blizzard Dialog'] LDK_ThemeSet
--- @field ['Blizzard Dialog Gold'] LDK_ThemeSet
--- @field ['Blizzard Party'] LDK_ThemeSet
--- @field ['Blizzard Tooltip'] LDK_ThemeSet
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

local DEF_BG = [[Interface\FriendsFrame\UI-Toast-Background]]
local BG_WHITE = [[interface\buttons\white8x8]]
local BD_DEFAULT = 'Default'
local BD_MINIMAL, BD_DARK_KNIGHT, BD_ABYSS = 'Minimal', 'Dark Knight', 'Abyss'

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
local function lsmFetchBg(name)
  assertsafe(str_notBlank(name), 'lsmFetchBg(name): name should be string')
  return lsm:Fetch(mt.BACKGROUND, name, true)
end
--- @param name Name
--- @return string?
local function lsmFetchBgCustom(name)
  assertsafe(str_notBlank(name), 'lsmFetchBgCustom(name): name should be string')
  return lsm:Fetch(mt.BACKGROUND_LDK, name, true)
end
--- @param name Name
--- @return string?
local function lsmFetchBorder(name)
  assertsafe(str_notBlank(name), 'lsmFetchBorder(name): name should be string')
  return lsm:Fetch(mt.BORDER, name, true)
end --- @param name Name

--- @return string?
local function lsmFetchBorderCustom(name)
  assertsafe(str_notBlank(name), 'lsmFetchBorderCustom(name): name should be string')
  return lsm:Fetch(mt.BORDER_LDK, name, true)
end

--- @package
--- @param theme LDK_ThemeSet
local function _RegisterBorderSetting(theme)
  local name = theme.name
  assertsafe(str_notBlank(name), '_BorderSetting(borderSetting.name) should be a valid string')
  lsm:Register(mt.BACKGROUND_LDK, name, theme.main.backdrop.bgFile)
  theme.main.backdrop.edgeFile = o:GetBorder(name)
  borderSettings[name] = theme
end

--- @package
--- @param borderSetting LDK_ThemeSet
local function _RegisterCustomBorderSetting(borderSetting)
  local requiredMsg = '_RegisterCustomBorderSetting(borderSetting): %s is required'
  assertsafe(borderSetting, requiredMsg, 'borderSetting')

  local name = borderSetting.name
  assertsafe(
    str_notBlank(name),
    '_RegisterCustomBorderSetting(borderSetting) %s should be a valid string',
    'borderSetting.name'
  )
  assertsafe(borderSetting.main.backdrop.bgFile, requiredMsg, 'main.backdrop.bgFile')
  assertsafe(borderSetting.main.backdrop.edgeFile, requiredMsg, 'main.backdrop.edgeFile')

  lsm:Register(mt.BACKGROUND_LDK, name, borderSetting.main.backdrop.bgFile)
  lsm:Register(mt.BORDER_LDK, name, borderSetting.main.backdrop.edgeFile)
  borderSettings[name] = borderSetting
end

local function __InitCustomBorders()
  _RegisterCustomBorderSetting({
    name = 'Default',
    --showGutterOutline = false,
    main = {
      backdrop = {
        bgFile = [[Interface\FriendsFrame\UI-Toast-Background]],
        edgeFile = [[Interface\FriendsFrame\UI-Toast-Border]],
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
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        tileSize = 4,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      },
    },
  })
  _RegisterCustomBorderSetting({
    name = BD_DARK_KNIGHT,
    main = {
      backdrop = {
        bgFile = DEF_BG,
        edgeFile = lsmFetchBorder(lbn.BLIZZARD_TOOLTIP),
        tile = false,
        tileEdge = false,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
        bgColor = { 0, 0, 0, 0.95 },
        borderColor = { 0.53, 0.53, 0.53, 1 },
      },
      header = {
        backdrop = {
          bgFile = lsmFetchBg(lbg.BLIZZARD_PARCHMENT),
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
    },
  })
  _RegisterCustomBorderSetting({
    name = BD_ABYSS,
    main = {
      backdrop = {
        bgFile = DEF_BG,
        edgeFile = [[interface\addons\actionbarplus-core\assets\textures\ui-tooltip-border-maw]],
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
        borderColor = { 1, 1, 1, 1.0 },
      },
      header = {
        backdrop = {
          bgFile = lsmFetchBg(lbg.BLIZZARD_TABARD_BACKGROUND),
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
    },
  })
  _RegisterCustomBorderSetting({
    name = BD_MINIMAL,
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
    },
  })
end

local function __InitBorders()
  __InitCustomBorders()

  _RegisterBorderSetting({
    name = lbn.BLIZZARD_ACHIEVEMENT_WOOD,
    label = 'Oakframe',
    main = {
      backdrop = {
        bgFile = DEF_BG,
        tile = false,
        tileEdge = false,
        edgeSize = 24,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
        borderColor = { 1, 1, 1, 1.0 },
      },
      header = {
        backdrop = {
          bgFile = lsmFetchBg(lbg.BLIZZARD_GARRISON_BACKGROUND),
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
  })
  _RegisterBorderSetting({
    name = lbn.BLIZZARD_CHAT_BUBBLE,
    label = 'Whisper',
    main = {
      backdrop = {
        bgFile = DEF_BG,
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
          bgFile = lsmFetchBg(lbg.BLIZZARD_PARCHMENT),
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
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.08, 0.08, 0.08, 0.5 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      },
    },
  })
  _RegisterBorderSetting({
    name = lbn.BLIZZARD_DIALOG,
    label = 'Stonecut',
    main = {
      backdrop = {
        bgFile = DEF_BG,
        tile = false,
        tileEdge = false,
        edgeSize = 24,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
        borderColor = { 1, 1, 1, 1.0 },
      },
      header = {
        backdrop = {
          bgFile = lsmFetchBg(lbg.BLIZZARD_COLLECTIONS_BACKGROUND),
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
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.1 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      },
    },
  })
  _RegisterBorderSetting({
    name = lbn.BLIZZARD_DIALOG_GOLD,
    label = 'Gilded',
    main = {
      backdrop = {
        bgFile = lsmFetchBg(lbg.BLIZZARD_DIALOG_BACKGROUND_GOLD),
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
          bgFile = lsmFetchBg(lbg.BLIZZARD_GARRISON_BACKGROUND_3),
          bgColor = { 1, 1, 1, 0.8 },
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
        insets = { left = 3, right = 3, top = 4, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.9 },
        borderColor = { 0.6, 0.6, 0.6, 0.1 },
      },
    },
  })
  _RegisterBorderSetting({
    name = lbn.BLIZZARD_PARTY,
    label = 'Warband',
    main = {
      backdrop = {
        bgFile = DEF_BG,
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
  })
  _RegisterBorderSetting({
    name = lbn.BLIZZARD_TOOLTIP,
    label = 'Ashen',
    main = {
      backdrop = {
        bgFile = DEF_BG,
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
  })
end

--[[-----------------------------------------------------------------------------
Methods & Fields
-------------------------------------------------------------------------------]]

--- @param name string @Border media name, from ns:GetBorders()
--- @return string?     @The edgeFile Texture path, or nil if name isn't registered
function o:GetBorder(name) return lsmFetchBorderCustom(name) or lsmFetchBorder(name) end

--- @param name string  @Background media name, from ns:GetBorders()
--- @return string?     @The edgeFile Texture path, or nil if name isn't registered
function o:GetBackground(name) return lsmFetchBgCustom(name) or lsmFetchBg(name) end

---@return LDK_ThemeSet
function o:GetDefaultBorderSettings() return borderSettings[BD_DEFAULT] end

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

--- This is a custom ordered border name list
--- @return string[]
function o:GetBorderNames()
  local main = lsm:List(mt.BORDER) --[[@as string[] ]]
  local custom = lsm:List(mt.BORDER_LDK) --[[@as string[] ]]

  -- "Default" first, then this addon's own (LuaDevKit-prefixed) custom
  -- borders, then everything else registered under the real mt.BORDER.
  local defaultBorder = self:GetDefaultBorderSettings()
  assert(is_tbl(defaultBorder), 'Unexpected Error:: default-border is nil or empty.')
  local merged = { defaultBorder.name, BD_MINIMAL }
  for _, name in ipairs(custom or {}) do
    if name ~= defaultBorder.name and name ~= BD_MINIMAL then merged[#merged + 1] = name end
  end
  for _, name in ipairs(main or {}) do
    merged[#merged + 1] = name
  end
  return merged
end

--- @param name Name
--- @return string @The theme's display label, or name if no override is set
function o:GetBorderLabel(name)
  local theme = self:GetBorderSettings(name)
  return (theme and theme.label) or name
end

--- @param callbackFn fun(name:string)
--- @param acceptFilterFn? fun(name:string) : boolean @Return true to accept (include) a border; defaults to accepting all
function o:ForEachBorder(callbackFn, acceptFilterFn)
  if not callbackFn then return end
  local fn = acceptFilterFn or acceptAll
  for _, name in ipairs(self:GetBorderNames()) do
    if fn(name) then callbackFn(name) end
  end
end

--[[-----------------------------------------------------------------------------
Last
-------------------------------------------------------------------------------]]
__InitBorders()
