local addon, ns = ...

local libName = 'Developer'
local AceEvent = LibStub('AceEvent-3.0')
---@class LDK_Core_Developer: AceEvent-3.0
local o = AceEvent:Embed({})
LDK_Core_Developer = o

function o:OnReady(evt, ...)
  self:ShowCodeEditor()
end

function o:ShowCodeEditor()
  --- @type LDK_CodeEditorDialog
  local dlg = LDK_CodeEditorDialog
  if not dlg then return end
  dlg:Configure( { fontFamily = 'SourceCodePro',
      fontSize = 10, wrapText = true } --[[@as LDK_CodeEditorOptions ]] )
  dlg:SetOnConfigChanged(function (self, options)
    tr(addon, libName, 'options=', fmt(options))
  end)
  dlg:Show()
end

o:RegisterMessage('LDK_CodeEditor_Developer::READY', 'OnReady')
