--[[-----------------------------------------------------------------------------
Backdrops
-------------------------------------------------------------------------------]]

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
---@field backdrop        BackdropTemplate
---@field bgColor         RGBA                           @The {r,g,b,a} each value 0.0–1.0, example: `{ 0.1, 0.3, 0.7, 0.8 }`
---@field borderColor     RGBA                           @The {r,g,b,a} each value 0.0–1.0, example: `{ 0.1, 0.3, 0.7, 0.8 }`
---@field borderPadBottom number                         @Internal-only extra bottom padding for themes whose border art needs more room at the bottom; not user-configurable
---@field padding         number                         @Default backdrop padding (uniform, all sides)
---@field basePadding     number                         @Internal-only base padding added around the button grid before user padding (default 8); not user-configurable

---@type table<string, LDK_BorderDef>
LDK_BORDER_DEFS = {

  ["minimal"] = {
    label = "Minimal",
    backdrop = {
      bgFile = "Interface\\Buttons\\WHITE8x8",   -- or any solid fill
      edgeFile = "Interface\\Buttons\\WHITE8x8", -- straight 1px edge, no corner art
      edgeSize = 1,
      insets = { left = 1, right = 1, top = 1, bottom = 1 }
    },
    bgColor = { 0.1, 0.1, 0.1, 0.1 },
    borderColor = { 0.6, 0.6, 0.6, 0.1 },
    padding = 0,
    basePadding = 6,
    borderPadBottom = 0.3,
    edgeSize = { default = 11, min = 11, max = 32 }
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
