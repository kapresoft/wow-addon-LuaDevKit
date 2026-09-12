local addon, ns = ...

local libName = "Developer"
local AceEvent = LibStub("AceEvent-3.0")
---@class LDK_Core_Developer: AceEvent-3.0
local o = AceEvent:Embed({})
LDK_Core_Developer = o

function o:OnReady(evt, ...)
	self:ShowCodeEditor()
end

function o:pf()
	if not SharedMediaFontsMono then
		return print("SharedMediaFontsMono is not available")
	end
  local loc = GetLocale()
  --local loc = 'koKR'
	SharedMediaFontsMono:ForEachFont(function(font)
	  local f = {}
	  f[font.name] = { path=font.path, cloc=loc, supportsLoc=font:supports(loc)}
	  DevTools_Dump(f)
	end)
	return true
end

--- @type LDK_CodeEditorDialog
local codeEditor

function o:ShowCodeEditor()
	if codeEditor then
		return codeEditor:Show()
	end
	codeEditor = LDK_CodeEditorDialog
	if not codeEditor then
		return
	end
	codeEditor:Configure({ fontFamilyX = "JetBrainsMono", fontSize = 12, wrapText = true } --[[@as LDK_CodeEditorOptions ]])
	codeEditor:SetOnConfigChanged(function(self, options)
		tr(addon, libName, "options=", fmt(options))
	end)
	codeEditor:Show()
end

o:RegisterMessage("LDK_CodeEditor_Developer::READY", "OnReady")
