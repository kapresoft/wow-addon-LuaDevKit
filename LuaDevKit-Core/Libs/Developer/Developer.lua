local addon, ns = ...

local libName = 'Developer'
local AceEvent = LibStub('AceEvent-3.0')
---@class LDK_Core_Developer: AceEvent-3.0
local o = AceEvent:Embed({})
LDK_Core_Developer = o

function o:OnReady(evt, ...)
  self:ShowCodeEditor()
end

--- @type LDK_CodeEditorDialog
local codeEditor

function o:ShowCodeEditor()
  if codeEditor then return codeEditor:Show() end
  codeEditor = LDK_CodeEditorDialog
  if not codeEditor then return end
  codeEditor:Configure( { fontFamily = 'JetBrainsMono',
      fontSize = 12, wrapText = true } --[[@as LDK_CodeEditorOptions ]] )
  codeEditor:SetOnConfigChanged(function (self, options)
    tr(addon, libName, 'options=', fmt(options))
  end)
  codeEditor:Show()
end

o:RegisterMessage('LDK_CodeEditor_Developer::READY', 'OnReady')
