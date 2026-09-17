--- @type LDK_Core_Namespace
local ns = select(2, ...)
local O = ns.O
local lsm = O.LSM
local mt, String = lsm.MediaType, O.String
local str_eq, str_empty = String.EqualsIgnoreCase, String.IsEmpty
local str_notBlank = String.IsNotBlank

local DEFAULT_EDGE_FILE = [[interface\addons\luadevkit-core\assets\ef1.tga]]

--[[-----------------------------------------------------------------------------
Backdrops
-------------------------------------------------------------------------------]]

--- @class LDK_Backdrops
local o = {}
O.Backdrops = o

--- @alias RGBA number[]  -- {r,g,b,a} each value 0.0–1.0

--[[-- BACKDROP_TOAST_12_12 with its edge dropped, for bars that should only show
-- a background fill (no border).
local BACKDROP_TOAST_12_12_NO_EDGE = {
	bgFile = BACKDROP_TOAST_12_12.bgFile,
	tile = BACKDROP_TOAST_12_12.tile,
	tileSize = BACKDROP_TOAST_12_12.tileSize,
	insets = BACKDROP_TOAST_12_12.insets,
}]]

---@class LDK_BorderDef
---@field label           string                         @Display name shown in the theme dropdown
---@field bgColor         RGBA                           @The {r,g,b,a} each value 0.0–1.0, example: `{ 0.1, 0.3, 0.7, 0.8 }`
---@field borderColor     RGBA                           @The {r,g,b,a} each value 0.0–1.0, example: `{ 0.1, 0.3, 0.7, 0.8 }`
---@field borderPadBottom number                         @Internal-only extra bottom padding for themes whose border art needs more room at the bottom; not user-configurable
---@field padding         number                         @Default backdrop padding (uniform, all sides)
---@field basePadding     number                         @Internal-only base padding added around the button grid before user padding (default 8); not user-configurable

local defaultBgColor = { 0.1, 0.1, 0.1, 0.1 }
local defaultBorderColor = { 0.6, 0.6, 0.6, 0.1 }

---@type table<string, LDK_BorderDef>
LDK_BORDER_DEFS = {

	["minimal"] = {
		label = "Minimal",
		backdrop = {
			bgFile = "Interface\\Buttons\\WHITE8x8", -- or any solid fill
			edgeFile = "Interface\\Buttons\\WHITE8x8", -- straight 1px edge, no corner art
			edgeSize = 1,
			insets = { left = 1, right = 1, top = 1, bottom = 1 },
		},
		bgColor = { 0.1, 0.1, 0.1, 0.1 },
		borderColor = { 0.6, 0.6, 0.6, 0.1 },
		padding = 0,
		basePadding = 6,
		borderPadBottom = 0.3,
		edgeSize = { default = 11, min = 11, max = 32 },
	},
	["modern"] = {
		label = "Modern",
		backdrop = {
			bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		},
		bgColor = { 0.1, 0.1, 0.1, 0.9 },
		borderColor = { 1, 1, 1, 1 },
		padding = 0,
		basePadding = 6,
		borderPadBottom = 0.3,
		edgeSize = { default = 11, min = 11, max = 32 },
	},

	["darkNight"] = {
		label = "Dark Knight",
		backdrop = {
			bgFile = [[interface\tooltips\chatbubble-background]],
			edgeFile = [[interface\tooltips\chatbubble-backdrop]],
			tile = true,
			tileSize = 32,
			edgeSize = 6,
			insets = { left = 6, right = 6, top = 6, bottom = 6 },
		},
		bgColor = { 0.8, 0.8, 0, 1 },
		borderColor = { 0.54, 0.55, 0.75, 1 },
		padding = 0,
		basePadding = 6,
		borderPadBottom = 1,
		edgeSize = { default = 21, min = 14, max = 28 },
		dialog = { showBgColor = false, showBorderSize = false },
	},

	["abyss"] = {
		label = "Abyss",
		backdrop = {
			bgFile = [[interface\tooltips\ui-tooltip-background]],
			edgeFile = [[interface\addons\actionbarplus-core\assets\textures\ui-tooltip-border-maw]],
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		},
		bgColor = { 0.04, 0.08, 0.09, 0.92 }, -- near-black with a cool teal undertone
		borderColor = { 1, 1, 1, 1 },
		padding = 3,
		basePadding = 6,
		borderPadBottom = 0,
		edgeSize = { default = 26, min = 21, max = 32 },
	},
}

--- @class LDK_Backdrop
--- @field bgFile string
--- @field edgeFile string
--- @field tile boolean?
--- @field tileEdge boolean?
--- @field tileSize number?
--- @field edgeSize number
--- @field insets { left: number, right: number, top: number, bottom: number }

--- @class LDK_BorderSetting
--- @field name Name
--- @field showGutterOutline? boolean @Defaults to true
--- @field backdrop LDK_Backdrop
--- @field bgColor RGBA
--- @field borderColor RGBA
--- @field main LDK_BorderSetting
--- @field code LDK_BorderSetting

--- @class LDK_BorderSettings : table<string, LDK_BorderSetting>
--- @field ['Blizzard Achievement Wood'] LDK_BorderSetting
--- @field ['Blizzard Chat Bubble'] LDK_BorderSetting
--- @field ['Blizzard Dialog'] LDK_BorderSetting
--- @field ['Blizzard Dialog Gold'] LDK_BorderSetting
--- @field ['Blizzard Party'] LDK_BorderSetting
--- @field ['Blizzard Tooltip'] LDK_BorderSetting
local borderSettings = {}

--- @type LDK_BorderSetting
local CODE_EDITOR_MAIN_FRAME_BORDER = {
	backdrop = {
		bgFile = [[Interface\FriendsFrame\UI-Toast-Background]],
		edgeFile = [[Interface\FriendsFrame\UI-Toast-Border]],
		tile = true,
		tileEdge = true,
		tileSize = 4,
		edgeSize = 8,
		insets = { left = 3, right = 3, top = 4, bottom = 3 },
	},
	bgColor = { 0.1, 0.1, 0.1, 0.1 },
	borderColor = { 0.6, 0.6, 0.6, 0.1 },
}

local DEF_BG = [[Interface\FriendsFrame\UI-Toast-Background]]

--- @type LDK_BorderSetting
local CODE_EDITBOX_BORDER = {
	backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile = true,
		tileEdge = true,
		tileSize = 4,
		edgeSize = 1,
		insets = { left = 3, right = 3, top = 4, bottom = 3 },
	},
	bgColor = CODE_EDITOR_MAIN_FRAME_BORDER.bgColor,
	borderColor = { 0.6, 0.6, 0.6, 0.1 },
}

--- @type LDK_Backdrop
local DEFAULT_CODE_EDITBOX_BACKDROP = {
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	tile = true,
	tileEdge = true,
	tileSize = 4,
	edgeSize = 1,
	insets = { left = 3, right = 3, top = 4, bottom = 3 },
}

--- @type LDK_BorderSetting
local defaultBorderSetting = {
	name = "Default",
	--showGutterOutline = false,
	--backdrop = {
	--	bgFile = [[Interface\FriendsFrame\UI-Toast-Background]],
	--	edgeFile = [[Interface\FriendsFrame\UI-Toast-Border]],
	--	tile = true,
	--	tileEdge = true,
	--	tileSize = 4,
	--	edgeSize = 8,
	--	insets = { left = 3, right = 3, top = 3, bottom = 3 },
	--},
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
		},
		bgColor = { 0.1, 0.1, 0.1, 0.1 },
		borderColor = { 0.6, 0.6, 0.6, 0.1 },
	},
	code = {
		backdrop = DEFAULT_CODE_EDITBOX_BACKDROP,
		bgColor = { 0.1, 0.1, 0.1, 0.1 },
		borderColor = { 0.6, 0.6, 0.6, 0.1 },
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
				--tileSize = 4,
				edgeSize = 42,
				insets = { left = 2, right = 2, top = 2, bottom = 2 },
			},
			bgColor = defaultBgColor,
			borderColor = defaultBorderColor,
		},
		code = {
			backdrop = DEFAULT_CODE_EDITBOX_BACKDROP,
			bgColor = { 0.1, 0.1, 0.1, 0.1 },
			borderColor = { 0.6, 0.6, 0.6, 0.1 },
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
			bgColor = defaultBgColor,
			borderColor = defaultBorderColor,
		},
		code = {
			backdrop = DEFAULT_CODE_EDITBOX_BACKDROP,
			bgColor = { 0.1, 0.1, 0.1, 0.1 },
			borderColor = { 0.6, 0.6, 0.6, 0.1 },
		},
	})

	_RegisterBorderSetting({
		name = "Blizzard Dialog",
		main = {
			backdrop = {
				tile = true,
				tileEdge = true,
				tileSize = 12,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
			},
			bgColor = defaultBgColor,
			borderColor = defaultBorderColor,
		},
		code = {
			backdrop = DEFAULT_CODE_EDITBOX_BACKDROP,
			bgColor = { 0.1, 0.1, 0.1, 0.1 },
			borderColor = { 0.6, 0.6, 0.6, 0.1 },
		},
	})
	_RegisterBorderSetting({
		name = "Blizzard Dialog Gold",
		main = {
			backdrop = {
				tile = true,
				tileEdge = true,
				tileSize = 12,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
			},
			bgColor = defaultBgColor,
			borderColor = defaultBorderColor,
		},
		code = {
			backdrop = DEFAULT_CODE_EDITBOX_BACKDROP,
			bgColor = { 0.1, 0.1, 0.1, 0.1 },
			borderColor = { 0.6, 0.6, 0.6, 0.1 },
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
			bgColor = defaultBgColor,
			borderColor = defaultBorderColor,
		},
		code = {
			backdrop = DEFAULT_CODE_EDITBOX_BACKDROP,
			bgColor = { 0.1, 0.1, 0.1, 0.1 },
			borderColor = { 0.6, 0.6, 0.6, 0.1 },
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
			bgColor = defaultBgColor,
			borderColor = defaultBorderColor,
		},
		code = {
			backdrop = DEFAULT_CODE_EDITBOX_BACKDROP,
			bgColor = { 0.1, 0.1, 0.1, 0.1 },
			borderColor = { 0.6, 0.6, 0.6, 0.1 },
		},
	})

	assert(str_notBlank(defaultBorderSetting.name), "Default LDK_BorderSetting.name is required")

	o:ForEachBorder(function(name)
		local bs = borderSettings[name]
		if bs then
			assert(str_notBlank(name), "LDK_BorderSetting.name is required")

			--bs.backdrop.bgFile = DEF_BG
			--bs.backdrop.edgeFile = o:GetBorder(name)

			-- todo: bgFile will be configurable using: LSM.MediaType.BACKGROUND List
			bs.main.backdrop.bgFile = DEF_BG
			bs.main.backdrop.edgeFile = o:GetBorder(name)
		end
	end)
end

--[[-----------------------------------------------------------------------------
Methods & Fields
-------------------------------------------------------------------------------]]

o.CODE_EDITOR_MAIN_FRAME_BORDER = CODE_EDITOR_MAIN_FRAME_BORDER
o.CODE_EDITBOX_BORDER = CODE_EDITBOX_BORDER

--- @param name string @Border media name, from ns:GetBorders()
--- @return string     @The edgeFile Texture path, or nil if name isn't registered
function o:GetBorder(name)
	return lsm:Fetch(mt.BORDER, name, false) or defaultBorderSetting.backdrop.edgeFile
end

--- @param name Name?         @Returns the default border setting if nil
--- @return LDK_BorderSetting
function o:GetBorderSettings(name)
	local bs = borderSettings[name] or defaultBorderSetting
	--tr("GetBorderSettings", "name=", name, "bs=", fmt(bs))
	return bs
end

--- @return string[]
function o:GetBorderNames()
	return lsm:List(mt.BORDER) --[[@as string[] ]]
end

--- @param callbackFn fun(name:string)
--- @param filterFn fun(name:string) : boolean @Return true to filter OUT (skip) a border
function o:ForEachBorder(callbackFn, filterFn)
	if not callbackFn then
		return
	end
	for _, name in ipairs(self:GetBorderNames()) do
		if not (filterFn and filterFn(name)) then
			callbackFn(name)
		end
	end
end

--[[-----------------------------------------------------------------------------
Last
-------------------------------------------------------------------------------]]
_LoadBorders()
