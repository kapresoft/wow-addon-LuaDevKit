--- @diagnostic disable: inject-field

--- @type LDK_Core_Namespace
local ns = select(2, ...)

local L = ns:NewLocale('zhTW')
if not L then return end

-- Untranslated keys fall back to enUS.
