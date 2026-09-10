--[[-----------------------------------------------------------------------------
CodeEditBoxMixin: the no-wrap EditBox used by CodeEditorDialog's code area.
Delegates each event back up to the owning dialog, resolved once in OnLoad.
-------------------------------------------------------------------------------]]

--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local libName = 'CodeEditBoxMixin'

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_CodeEditBoxMixin : EditBox
--- @field owner LDK_CodeEditorDialogMixin The dialog this EditBox belongs to
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

-- First Escape: just unfocus the EditBox. Once it's unfocused, a second
-- Escape reaches the dialog's own OnKeyDown (enableKeyboard="true") and
-- closes it -- EditBox focus is what was eating the keystroke before.
function o:OnEscapePressed()
  --tr(ns.addon, libName, 'OnEscapePressed...')
  self:ClearFocus()
end

function o:OnTextChanged()
  --tr(ns.addon, libName, 'OnTextChanged...')
  self.owner:OnCodeEditBoxTextChanged()
end


-- No OnSizeChanged handler: RefreshGutter is the only thing that resizes this
-- EditBox, so reacting to that here just fed itself. See CodeEditorDialog.xml.
--
-- Blizzard's ScrollingEdit_OnCursorChanged/ScrollingEdit_OnUpdate pair was also
-- tried here and self-sustained its own loop (OnUpdate scrolls to chase the
-- caret, the scroll moves the caret's coordinates, which re-flags it). Worth
-- revisiting for scroll-to-caret now that the resize churn is gone.
function o:OnCursorChanged(x, y, w, h)
  --tr(ns.addon, libName, 'OnCursorChanged...')
  self.owner:OnCodeEditBoxCursorChanged(x, y, w, h)
end