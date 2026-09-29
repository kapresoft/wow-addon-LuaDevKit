--- @type LDK_Core_Namespace
local ns = select(2, ...)

--- @class LDK_TextUtil
local o = {}; ns.O.TextUtil = o

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- Iterates each line; a trailing '\n' yields a final empty line.
--- @param text string
--- @return fun(): string?
function o:Lines(text) return (text .. '\n'):gmatch('(.-)\n') end
