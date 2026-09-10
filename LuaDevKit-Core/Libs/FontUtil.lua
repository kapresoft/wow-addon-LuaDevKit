--[[-----------------------------------------------------------------------------
FontUtil: available code-editor fonts (family choices + supported sizes),
including locale-gated CJK support. Lazily built and cached on first call, so
it's independent of load order relative to Fonts.xml's global font objects.
-------------------------------------------------------------------------------]]
--- @type string, table
local addon, xns = ...

--- @class LDK_Core_Namespace
local ns = xns

--- @class LDK_FontChoice
--- @field key string Stable identifier, e.g. 'UbuntuMono'. Independent of label so relabeling doesn't break persisted config.
--- @field label string Display text for a font dropdown.
--- @field supportsCJK boolean Whether this face carries Chinese/Japanese/Korean glyphs.
--- @field bySize table<number, Font> Font object per supported size (10/12/14).

--- @class LDK_FontUtil
ns.O.FontUtil = {}
local FontUtil = ns.O.FontUtil

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
-- Sizes supported by Fonts.xml: one font object per family per size (no
-- runtime CreateFont/SetFont -- picking a size is the same SetFontObject
-- swap as picking a family).
local FONT_SIZES = { 10, 12, 14 }

-- Only the client's own CJK locale (zhCN/zhTW/koKR) gets a Noto Sans Mono
-- CJK entry -- Fonts.xml declares all three locale variants, but there's no
-- reason to offer Chinese/Korean glyph sets to a client that can't display
-- their own script. WoW has no Japanese client locale, so there's no jaJP
-- case here.
local CJK_LOCALES = { zhCN = true, zhTW = true, koKR = true }

--- @type LDK_FontChoice[]?
local fontChoices

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- supportsCJK: none of the base fonts carry Chinese/Japanese/Korean glyphs
--- (all three are Latin/Cyrillic-only monospace faces) -- kept explicit here
--- rather than assumed, so CJK-locale handling has real metadata to check
--- instead of guessing from the font name.
--- @return LDK_FontChoice[]
function FontUtil:GetFontChoices()
  if fontChoices then return fontChoices end

  fontChoices = {
    {
      key = 'UbuntuMono',
      label = 'Ubuntu Mono',
      supportsCJK = false,
      bySize = {
        [10] = LDK_CodeEditorFont_UbuntuMono_10,
        [12] = LDK_CodeEditorFont_UbuntuMono_12,
        [14] = LDK_CodeEditorFont_UbuntuMono_14,
      },
    },
    {
      key = 'JetBrainsMono',
      label = 'JetBrains Mono',
      supportsCJK = false,
      bySize = {
        [10] = LDK_CodeEditorFont_JetBrainsMono_10,
        [12] = LDK_CodeEditorFont_JetBrainsMono_12,
        [14] = LDK_CodeEditorFont_JetBrainsMono_14,
      },
    },
    {
      key = 'SourceCodePro',
      label = 'Source Code Pro',
      supportsCJK = false,
      bySize = {
        [10] = LDK_CodeEditorFont_SourceCodePro_10,
        [12] = LDK_CodeEditorFont_SourceCodePro_12,
        [14] = LDK_CodeEditorFont_SourceCodePro_14,
      },
    },
  }

  -- The font objects are named LDK_CodeEditorFont_NotoSansMonoCJK_<locale>_<size>,
  -- so the right one is a _G lookup keyed off GetLocale() rather than three
  -- separate static entries.
  local clientLocale = GetLocale()
  if CJK_LOCALES[clientLocale] then
    table.insert(fontChoices, {
      key = 'NotoSansMonoCJK',
      label = 'Noto Sans Mono CJK',
      supportsCJK = true,
      bySize = {
        [10] = _G['LDK_CodeEditorFont_NotoSansMonoCJK_' .. clientLocale .. '_10'],
        [12] = _G['LDK_CodeEditorFont_NotoSansMonoCJK_' .. clientLocale .. '_12'],
        [14] = _G['LDK_CodeEditorFont_NotoSansMonoCJK_' .. clientLocale .. '_14'],
      },
    })
  end

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

--- Nearest supported size (Fonts.xml only declares 10/12/14 per family).
--- @param fontSize number
--- @return number
function FontUtil:NearestFontSize(fontSize)
  local nearest = FONT_SIZES[1]
  for _, size in ipairs(FONT_SIZES) do
    if math.abs(size - fontSize) < math.abs(nearest - fontSize) then nearest = size end
  end
  return nearest
end