--[[-----------------------------------------------------------------------------
FontUtil: available code-editor fonts (family choices + supported sizes),
filtered to the faces the client locale can actually render. The font list
and each face's file come from the SharedMediaFontsMono catalog; the Font
objects themselves are built here via CreateFont/SetFont, one per family per
size. Lazily built and cached on first call.
-------------------------------------------------------------------------------]]
--- @type string, table
local addon, xns = ...

--- @class LDK_Core_Namespace
local ns = xns

--- @class LDK_FontChoice
--- @field key string Identifier derived from the catalog name, e.g. 'UbuntuMono'. Persisted in config, so renaming a catalog font invalidates a saved selection.
--- @field label string Display text for a font dropdown.
--- @field supportsLocale boolean Whether this face font supports the current CJK locale
--- @field bySize table<number, Font> Font object per supported size (10/12/14).

--- @class LDK_FontUtil
ns.O.FontUtil = {}
local FontUtil = ns.O.FontUtil

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
-- Sizes offered per family: one font object built per family per size, so
-- picking a size is the same SetFontObject swap as picking a family.
local FONT_SIZES = { 10, 12, 14 }

-- Created font objects are named LDK_CodeEditorFont_<CatalogName>_<size>,
-- with CatalogName being the catalog name stripped of spaces and parentheses.
local FONT_OBJECT_PREFIX = 'LDK_CodeEditorFont_'

--- @type LDK_FontChoice[]?
local fontChoices

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param fontName string
--- @return string @Catalog name reduced to a bare identifier for use as a key and in the created font object's name.
local function ObjectKey(fontName) return (fontName:gsub('[%s%(%)]', '')) end

--- Catalog faces the client locale can render, in the catalog's sorted order.
--- A face is offered only when it covers the client's own script, so a CJK
--- client sees just its Noto Sans Mono variant (which carries Latin and
--- Cyrillic glyphs too) instead of Latin-only faces that can't render its
--- script at all.
--- @return LDK_FontChoice[]
function FontUtil:GetFontChoices()
  if fontChoices then return fontChoices end

  local clientLocale = GetLocale()
  fontChoices = {}

  SharedMediaFontsMono:ForEachFont(function(font)
    if not font:supports(clientLocale) then return end

    local key = ObjectKey(font.name)
    local bySize = {}
    for _, size in ipairs(FONT_SIZES) do
      local objectName = FONT_OBJECT_PREFIX .. key .. '_' .. size
      local fontObject = CreateFont(objectName)
      fontObject:SetFont(font.path, size, '')
      fontObject:SetTextColor(WHITE_FONT_COLOR:GetRGB())
      bySize[size] = fontObject
    end
    C_Timer.After(1, function()
      DevTools_Dump({['key'] = key})
    end)
    fontChoices[#fontChoices + 1] = {
      key = key,
      label = font.name,
      supportsLocale = font:supports(clientLocale),
      bySize = bySize,
    }
  end)

  return fontChoices
end

--- @param key string
--- @return LDK_FontChoice|nil
function FontUtil:FindFontChoice(key)
  for _, choice in ipairs(self:GetFontChoices()) do
    if choice.key == key then return choice end
  end
  return nil
end

--- @return number[]
function FontUtil:GetFontSizes()
  return FONT_SIZES
end

--- Nearest supported size (only 10/12/14 are built per family).
--- @param fontSize number
--- @return number
function FontUtil:NearestFontSize(fontSize)
  local nearest = FONT_SIZES[1]
  for _, size in ipairs(FONT_SIZES) do
    if math.abs(size - fontSize) < math.abs(nearest - fontSize) then nearest = size end
  end
  return nearest
end