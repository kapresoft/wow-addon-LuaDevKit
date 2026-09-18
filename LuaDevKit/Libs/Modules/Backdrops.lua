--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local lsm = O.LSM
local mt, String = lsm.MediaType, O.String
local str_eq, str_empty = String.EqualsIgnoreCase, String.IsEmpty
local str_notBlank = String.IsNotBlank

--[[-----------------------------------------------------------------------------
Backdrops
-------------------------------------------------------------------------------]]
--- @class LDK_Backdrops
local o, libName = {}, 'Backdrops'; O.Backdrops = o

--[[-----------------------------------------------------------------------------
Type Definitions
-------------------------------------------------------------------------------]]
--- @alias RGBA number[]  -- {r,g,b,a} each value 0.0–1.0

---@class LDK_BorderDef
---@field label           string @Display name shown in the theme dropdown
---@field bgColor         RGBA   @The {r,g,b,a} each value 0.0–1.0, example: `{ 0.1, 0.3, 0.7, 0.8 }`
---@field borderColor     RGBA   @The {r,g,b,a} each value 0.0–1.0, example: `{ 0.1, 0.3, 0.7, 0.8 }`
---@field borderPadBottom number @Internal-only extra bottom padding for themes whose border art needs more room at the bottom; not user-configurable
---@field padding         number @Default backdrop padding (uniform, all sides)
---@field basePadding     number @Internal-only base padding added around the button grid before user padding (default 8); not user-configurable

--- @class LDK_Backdrop
--- @field bgFile string
--- @field edgeFile string
--- @field tile boolean?
--- @field tileEdge boolean?
--- @field tileSize number?
--- @field edgeSize number
--- @field insets { left: number, right: number, top: number, bottom: number }
--- @field bgColor? RGBA @Optional override
--- @field borderColor? RGBA @Optional override

--- @class LDK_BorderSetting
--- @field name Name
--- @field showGutterOutline? boolean @Defaults to true
--- @field backdrop LDK_Backdrop
--- @field main LDK_BorderSetting
--- @field code LDK_BorderSetting
--- @field header LDK_BorderSetting

--- @class LDK_HeaderSetting
--- @field backdrop LDK_Backdrop
--- @field height number @The header height

--- @class LDK_BorderSettings : table<string, LDK_BorderSetting>
--- @field ['Blizzard Achievement Wood'] LDK_BorderSetting
--- @field ['Blizzard Chat Bubble'] LDK_BorderSetting
--- @field ['Blizzard Dialog'] LDK_BorderSetting
--- @field ['Blizzard Dialog Gold'] LDK_BorderSetting
--- @field ['Blizzard Party'] LDK_BorderSetting
--- @field ['Blizzard Tooltip'] LDK_BorderSetting
local borderSettings = {}

local defaultBgColor = { 0.1, 0.1, 0.1, 0.1 }
local defaultBorderColor = { 0.6, 0.6, 0.6, 0.1 }

--- @see LibSharedMedia-3.0
local LSM_BACKGROUND_NAMES = {
  BLIZZARD_COLLECTIONS_BACKGROUND = "Blizzard Collections Background",
  BLIZZARD_DIALOG_BACKGROUND = "Blizzard Dialog Background",
  BLIZZARD_DIALOG_BACKGROUND_DARK = "Blizzard Dialog Background Dark",
  BLIZZARD_DIALOG_BACKGROUND_GOLD = "Blizzard Dialog Background Gold",
  BLIZZARD_GARRISON_BACKGROUND = "Blizzard Garrison Background",
  BLIZZARD_GARRISON_BACKGROUND_2 = "Blizzard Garrison Background 2",
  BLIZZARD_GARRISON_BACKGROUND_3 = "Blizzard Garrison Background 3",
  BLIZZARD_LOW_HEALTH = "Blizzard Low Health",
  BLIZZARD_MARBLE = "Blizzard Marble",
  BLIZZARD_OUT_OF_CONTROL = "Blizzard Out of Control",
  BLIZZARD_PARCHMENT = "Blizzard Parchment",
  BLIZZARD_PARCHMENT_2 = "Blizzard Parchment 2",
  BLIZZARD_ROCK = "Blizzard Rock",
  BLIZZARD_TABARD_BACKGROUND = "Blizzard Tabard Background",
  BLIZZARD_TOOLTIP = "Blizzard Tooltip",
  SOLID = "Solid",
}; local lbg = LSM_BACKGROUND_NAMES

--- @see LibSharedMedia-3.0
local LSM_BLIZZ_NAMES = {
  BLIZZARD_ACHIEVEMENT_WOOD = "Blizzard Achievement Wood",
  BLIZZARD_CHAT_BUBBLE = "Blizzard Chat Bubble",
  BLIZZARD_DIALOG = "Blizzard Dialog",
  BLIZZARD_DIALOG_GOLD = "Blizzard Dialog Gold",
  BLIZZARD_PARTY = "Blizzard Party",
  BLIZZARD_TOOLTIP = "Blizzard Tooltip",
}; local lbn = LSM_BLIZZ_NAMES


--[[-----------------------------------------------------------------------------
Custom Backdrops
-------------------------------------------------------------------------------]]

--- @param color colorRGBA
--- @param a alpha
--- @return number, number, number, alpha @Red, Green, Blue
local function rgb(color, a) return color.r, color.g, color.b, a end

--- @param color colorRGBA
--- @return number, number, number, alpha @Red, Green, Blue, Alpha
local function rgba(color) return color.r, color.g, color.b, color.a --[[@as alpha ]] end

local DEF_BG = [[Interface\FriendsFrame\UI-Toast-Background]]
local BG_WHITE = [[interface\buttons\white8x8]]

local BD_MINIMAL = ('%s Minimal'):format(ns.addon)
local BD_DARK_KNIGHT = ('%s Dark Knight'):format(ns.addon)
local BD_ABYSS = ('%s Abyss'):format(ns.addon)

local LSM_BG_OVERRIDES = {
  [lbn.BLIZZARD_ACHIEVEMENT_WOOD] = { [mt.BACKGROUND] = DEF_BG },
  [lbn.BLIZZARD_CHAT_BUBBLE] = { [mt.BACKGROUND] = DEF_BG },
  [lbn.BLIZZARD_DIALOG] = { [mt.BACKGROUND] = DEF_BG },
  [lbn.BLIZZARD_DIALOG_GOLD] = { [mt.BACKGROUND] = DEF_BG },
  [lbn.BLIZZARD_PARTY] = { [mt.BACKGROUND] = DEF_BG },
  [lbn.BLIZZARD_TOOLTIP] = { [mt.BACKGROUND] = DEF_BG },
}

--- @type table<string, LDK_HeaderSetting>
local HEADER_BACKDROP_OVERRIDES = {
  [lbn.BLIZZARD_ACHIEVEMENT_WOOD] = {
    backdrop = {
      bgFile = lsm:Fetch(mt.BACKGROUND, lbg.BLIZZARD_GARRISON_BACKGROUND, true),
      bgColor = { 1, 1, 1, 1.0 },
      edgeSize = 16
    },
    height = 32
  },
  [lbn.BLIZZARD_DIALOG_GOLD] = {
    backdrop = {
      bgFile = lsm:Fetch(mt.BACKGROUND, lbg.BLIZZARD_GARRISON_BACKGROUND_3, true),
    },
    height = 35
  },
  [lbn.BLIZZARD_DIALOG] = {
    backdrop = {
      bgFile = lsm:Fetch(mt.BACKGROUND, lbg.BLIZZARD_GARRISON_BACKGROUND_2, true),
    },
    height = 35
  }

}

local CUSTOM_BACKDROPS = {
  -- val[1]: bg, val[2]: border
  [BD_MINIMAL] = { BG_WHITE, BG_WHITE },
  [BD_DARK_KNIGHT] = { DEF_BG, [[interface\tooltips\chatbubble-backdrop]] },
  [BD_ABYSS] = { DEF_BG, [[interface\addons\actionbarplus-core\assets\textures\ui-tooltip-border-maw]] },
}
--- @return string?
local function lsmKey(key)
  assert(str_notBlank(key), 'lsmKey(key) requires a string key')
  return ('%s_%s'):format(strlower(ns.addon), strlower(key))
end
local CUSTOM_BG = lsmKey(mt.BACKGROUND)
local CUSTOM_BORDER = lsmKey(mt.BORDER)
--tr(libName, 'lsmKey', 'CUSTOM_BORDER=', CUSTOM_BORDER, 'CUSTOM_BG=', CUSTOM_BG)

for name, paths in pairs(CUSTOM_BACKDROPS) do
  lsm:Register(CUSTOM_BG, name, paths[1])
  lsm:Register(CUSTOM_BORDER, name, paths[2])
  --lsm:Register(mt.BACKGROUND, name, paths[1])
  --lsm:Register(mt.BORDER, name, paths[2])
end

--- @type LDK_BorderSetting
local defaultBorderSetting = {
	name = "Default",
	--showGutterOutline = false,
	main = {
		backdrop = {
			bgFile = [[Interface\FriendsFrame\UI-Toast-Background]],
			edgeFile = [[Interface\FriendsFrame\UI-Toast-Border]],
			--edgeFile = DEFAULT_EDGE_FILE,
			tile = true,
			tileEdge = true,
			tileSize = 4,
			edgeSize = 8,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
			--bgColor = { 1, 1, 1, 1 },
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
}

----- @deprecated
--local MAIN_BACKDROP = {
--	bgFile = [[Interface\FriendsFrame\UI-Toast-Background]],
--	edgeFile = [[Interface\FriendsFrame\UI-Toast-Border]],
--	tile = true,
--	tileEdge = true,
--	tileSize = 4,
--	edgeSize = 8,
--	insets = { left = 3, right = 3, top = 4, bottom = 3 },
--}

--- @package
--- @param borderSetting LDK_BorderSetting
local function _RegisterBorderSetting(borderSetting)
	assertsafe(str_notBlank(borderSetting.name), "_BorderSetting(borderSetting.name) should be a valid string")
	borderSettings[borderSetting.name] = borderSetting
end

local function _LoadBorders()
	-- todo: centralize MAIN_BACKDROP
	borderSettings["Default"] = defaultBorderSetting

	_RegisterBorderSetting({
		name = "Blizzard Achievement Wood",
		main = {
			backdrop = {
				tile = true,
				tileEdge = true,
				edgeSize = 42,
				insets = { left = 2, right = 2, top = 2, bottom = 2 },
				borderColor = { 1, 1, 1, 1.0 },
			},
		},
		header = {
		  backdrop = {
		    edgeSize = 8
		  }
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

	_RegisterBorderSetting({
		name = "Blizzard Chat Bubble",
		main = {
			backdrop = {
				tile = true,
				tileEdge = true,
				tileSize = 4,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
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

	_RegisterBorderSetting({
		name = "Blizzard Dialog",
		main = {
			backdrop = {
				tile = true,
				tileEdge = true,
				tileSize = 12,
				edgeSize = 24,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
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
	_RegisterBorderSetting({
		name = "Blizzard Dialog Gold",
		main = {
			backdrop = {
				tile = true,
				tileEdge = true,
				tileSize = 12,
				edgeSize = 24,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
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
	_RegisterBorderSetting({
		name = "Blizzard Party",
		main = {
			backdrop = {
				tile = true,
				tileEdge = true,
				tileSize = 8,
				edgeSize = 6,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
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
	_RegisterBorderSetting({
		name = "Blizzard Tooltip",
		main = {
			backdrop = {
				tile = true,
				tileEdge = true,
				tileSize = 32,
				edgeSize = 16,
				insets = { left = 3, right = 3, top = 3, bottom = 3 },
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

	_RegisterBorderSetting({
		name = BD_DARK_KNIGHT,
		main = {
			backdrop = {
				edgeSize = 16,
				insets = { left = 3, right = 3, top = 3, bottom = 3 },
				bgColor = { 0, 0, 0, 0.93 },
			},
		},
		code = {
			backdrop = {
				edgeFile = [[Interface\Buttons\WHITE8x8]],
				tileEdge = true,
				tileSize = 4,
				edgeSize = 1,
				insets = { left = 3, right = 3, top = 4, bottom = 3 },
				bgColor = { 0.1, 0.1, 0.1, 0.1 },
				borderColor = { rgb(GRAY_FONT_COLOR, 0.2) },
			},
		},
	})

	_RegisterBorderSetting({
		name = BD_ABYSS,
		main = {
			backdrop = {
				edgeSize = 16,
				insets = { left = 3, right = 3, top = 3, bottom = 3 },
			},
		},
		code = {
			backdrop = {
				edgeFile = [[Interface\Buttons\WHITE8x8]],
				tileEdge = true,
				tileSize = 4,
				edgeSize = 1,
				insets = { left = 3, right = 3, top = 4, bottom = 3 },
				bgColor = { 0.1, 0.1, 0.1, 0.1 },
				borderColor = { rgb(GRAY_FONT_COLOR, 0.2) },
			},
		},
	})

	_RegisterBorderSetting({
		name = BD_MINIMAL,
		main = {
			backdrop = {
			  bgFile = BG_WHITE,
			  edgeFile = BG_WHITE,
				edgeSize = 1,
				insets = { left = 1, right = 1, top = 1, bottom = 1 },
				bgColor = { 0.1, 0.1, 0.1, 0.98 },
				borderColor = { rgb(LIGHTGRAY_FONT_COLOR, 0.75) },
			},
		},
		code = {
			backdrop = {
				edgeFile = [[Interface\Buttons\WHITE8x8]],
				tileEdge = true,
				tileSize = 4,
				edgeSize = 1,
				insets = { left = 3, right = 3, top = 4, bottom = 3 },
				bgColor = { 0.1, 0.1, 0.1, 0.1 },
				borderColor = { rgb(GRAY_FONT_COLOR, 0.2) },
			},
		},
	})


	assert(str_notBlank(defaultBorderSetting.name), "Default LDK_BorderSetting.name is required")

	o:ForEachBorder(function(name)
		local bs = borderSettings[name]
		--local bg = lsm:Fetch(mt.BORDER, name, true)
		if bs then
			assert(str_notBlank(name), "LDK_BorderSetting.name is required")

			--bs.backdrop.bgFile = DEF_BG
			--bs.backdrop.edgeFile = o:GetBorder(name)

			-- todo: bgFile will be configurable using: LSM.MediaType.BACKGROUND List
			bs.main.backdrop.bgFile = o:GetBackground(name)
			bs.main.backdrop.edgeFile = o:GetBorder(name)
		end
	end)
end

--[[-----------------------------------------------------------------------------
Methods & Fields
-------------------------------------------------------------------------------]]

--- @param name string @Border media name, from ns:GetBorders()
--- @return string     @The edgeFile Texture path, or nil if name isn't registered
function o:GetBorder(name)
	return lsm:Fetch(mt.BORDER, name, true)
	  or lsm:Fetch(lsmKey(mt.BORDER):lower(), name, true)
	  or defaultBorderSetting.main.backdrop.edgeFile
end

--- @param name string  @Background media name, from ns:GetBorders()
--- @return string?     @The edgeFile Texture path, or nil if name isn't registered
function o:GetBackground(name)
  local override = LSM_BG_OVERRIDES[name]
  if override and override[mt.BACKGROUND] then return override[mt.BACKGROUND] end
	return lsm:Fetch(mt.BACKGROUND, name, true)
	  or lsm:Fetch(lsmKey(mt.BACKGROUND), name, true)
end

---@param name Name? @Returns the default border setting if nil
---@return LDK_BorderSetting
function o:GetBorderSettings(name)
	local bs = borderSettings[name] or defaultBorderSetting
	return bs
end

local Table = O.Table
local Tbl_DeepCopy = Table.DeepCopy

--- Header Settings are derived from main with overrides in header
--- @param name Name? @Returns the default border setting if nil
--- @return LDK_HeaderSetting?
function o:GetHeaderSettings(name)
  local bs = self:GetBorderSettings(name)
  if not bs then return nil end
  --- @type LDK_HeaderSetting
  local override = Tbl_DeepCopy(HEADER_BACKDROP_OVERRIDES[bs.name])
  if not override then return nil end
  --- @type LDK_Backdrop
  override.backdrop = Table.MergeRecursive(bs.main.backdrop, override.backdrop)
  return override
end

--- @return string[]
function o:GetBorderNames()
  -- todo: merge CUSTOM_BACKDROPS names here
	return lsm:List(mt.BORDER) --[[@as string[] ]]
end

--- @param callbackFn fun(name:string)
--- @param filterFn fun(name:string) : boolean @Return true to filter OUT (skip) a border
function o:ForEachBorder(callbackFn, filterFn)
	if not callbackFn then return end
	for _, name in ipairs(self:GetBorderNames()) do
		if not (filterFn and filterFn(name)) then callbackFn(name) end
	end
  --- @type string[]
  local custom = lsm:List(lsmKey(mt.BORDER))
  tr(libName, 'custom=', custom)
  if not custom then return end
	for _, name in ipairs(custom) do
		if not (filterFn and filterFn(name)) then callbackFn(name) end
	end
end

--[[-----------------------------------------------------------------------------
Last
-------------------------------------------------------------------------------]]
_LoadBorders()
