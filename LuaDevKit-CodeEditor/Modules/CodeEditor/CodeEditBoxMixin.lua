--[[-----------------------------------------------------------------------------
CodeEditBoxMixin: the EditBox used by CodeEditorDialog's code area.
Delegates each event back up to the owning dialog, resolved once in OnLoad.
-------------------------------------------------------------------------------]]

--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local libName = 'CodeEditBoxMixin'

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_CodeEditBoxMixin : EditBox
--- @field owner LDK_CodeEditorDialogMixin @The dialog this EditBox belongs to
LDK_CodeEditBoxMixin = {}
local o = LDK_CodeEditBoxMixin

--
--- @class LDK_CodeEditBox : LDK_CodeEditBoxMixin
--

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
function o:OnLoad()
  -- EditBox -> ScrollFrame (its ScrollChild parent) -> dialog
  self.owner = self:GetParent():GetParent()
end

--- Unfocus only; the next Escape closes the dialog.
function o:OnEscapePressed()
  --tr(ns.addon, libName, 'OnEscapePressed...')
  self:ClearFocus()
end

function o:OnTextChanged()
  self.owner:OnCodeEditBoxTextChanged()
end

--- Swallows every key; propagated ones moved the character.
--- @param key string
function o:OnKeyDown(key)
  if key == 'PAGEUP' or key == 'PAGEDOWN' then
    self.owner:OnCodeEditBoxPageKey(key)
  elseif (key == 'HOME' or key == 'END') and IsMetaKeyDown() then
    -- Ctrl+Home/End is native; Cmd (IsMetaKeyDown) is not.
    self.owner:OnCodeEditBoxDocumentJumpKey(key)
  end
  self:SetPropagateKeyboardInput(false)
end

-- todo: retry ScrollingEdit_OnCursorChanged for scroll-to-caret
function o:OnCursorChanged(x, y, w, h)
  self.owner:OnCodeEditBoxCursorChanged(x, y, w, h)
end
