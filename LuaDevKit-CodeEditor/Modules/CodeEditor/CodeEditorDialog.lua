--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local CO = ns:cO()
local bdrops, String, fut, FAIAP = CO.Backdrops, CO.String, CO.FontUtil, CO.FAIAP
local LR, TU = CO.LuaRunner, CO.TextUtil
local OutputLog, DS, DB = CO.OutputLog, CO.DocumentStore, CO.Database
local str_eq, str_isBlank = String.EqualsIgnoreCase, String.IsBlank
local L = ns:GetLocale()
local upk = unpack
local libName = 'CodeEditorDialog'

-- todo: double-click selects word

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local CreateFrame = CreateFrame
local strlenutf8 = strlenutf8

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
local GUTTER = {
  borderColor = { 0.133, 0.341, 0.031, 0 },
  bgColor = { 0, 0, 0, 0 },
  textColor = { 1, 1, 1, 1.0 },
}

local HEADER_HEIGHT = 28

local MIN_STATUS_HEIGHT = 40
local MIN_CODE_HEIGHT = 60

-- Matches StatusDivider's Size y in XML.
local STATUS_DIVIDER_HEIGHT = 10

-- Matches CommandBar's Size y in XML; fixed, never resizes.
local COMMAND_BAR_HEIGHT = 22

-- Resting alpha for the code area's floating buttons.
local OVERLAY_ALPHA = 0.53

-- Alpha for disabled-looking output arrows.
local ARROW_ENABLED_ALPHA, ARROW_DISABLED_ALPHA = OVERLAY_ALPHA, 0.2

-- Tints RunButton's arrow art, which is gold like the output arrows.
local RUN_ICON_COLOR = GREEN_FONT_COLOR

-- Gap between the outer toolbar icons and the code area's top.
local TOOLBAR_ICON_LIFT = 6

-- Space above the toolbar icons, inside TopBar.
local TOOLBAR_TOP_PAD = 2

-- Toolbar icon edge length, and the gap between toolbar controls.
local TOOLBAR_ICON_SIZE, TOOLBAR_ICON_GAP = 24, 1

-- Set in Lua: an XML Size missing a value zeroes it.
local DOC_DROPDOWN_WIDTH = 150

-- How much shorter the document dropdown is than the icons.
local DOC_DROPDOWN_INSET = 4

-- Output lines kept; same truncation reasoning as MAX_LINES.
local MAX_OUTPUT_LINES = 500

-- Rows per wheel notch; 1 matches the old ScrollUp/ScrollDown.
local OUTPUT_SCROLL_LINES = 1

-- Fewest digits the gutter is sized for.
local MIN_GUTTER_DIGITS = 2

-- Longest snippet this scratchpad editor holds.
local MAX_LINES = 3000

-- Shared by both viewports to keep gutter/code rows aligned.
local VIEWPORT_TOP_BOTTOM_INSET = 3

-- Space between the last digit and the code panel (plus 4 visible).
local GUTTER_TEXT_RIGHT_INSET = 10

-- Gutter width beyond digits: XML insets plus text inset and margin.
local GUTTER_PADDING = 5 + 4 + GUTTER_TEXT_RIGHT_INSET + 4

-- Extra room an EditBox needs beyond the measured digit width.
local GUTTER_SLACK = 0

-- Arrow dropdown glyph; sized by the atlas, not the button.
local DROPDOWN_ARROW_SIZE = 18

-- StaticPopupDialogs key for the unsaved-document prompt.
local UNSAVED_PROMPT = 'LDK_CODE_EDITOR_UNSAVED'

-- StaticPopupDialogs key for the delete-document confirm.
local DELETE_PROMPT = 'LDK_CODE_EDITOR_DELETE'

-- StaticPopupDialogs key for the rename and save-as prompt.
local NAME_PROMPT = 'LDK_CODE_EDITOR_DOC_NAME'
local DOC_NAME_MAX_LETTERS = 40

-- Seconds off a menu before it closes; covers the button gap.
local MENU_LEAVE_DELAY = 0.3
local MENU_LEAVE_POLL = 0.1

-- Echoed commands in the output; ASCII so every code font has it.
local COMMAND_ECHO_PREFIX = '> '

-- Prefixed to the open document's name while it has unsaved edits.
local DIRTY_MARK = '*'

-- First document of a profile that has none.
local STARTER_CODE = [==[
-- example
print('Build Info=', GetBuildInfo())
]==]

-- Commands kept for Up/Down and the history menu.
local MAX_COMMAND_HISTORY = 50

-- History menu height before it scrolls.
local HISTORY_MENU_MAX_HEIGHT = 150

-- Document menu height before it scrolls; about 10 rows.
local DOC_MENU_MAX_HEIGHT = 200

-- History row text width cap; WoW truncates longer lines.
local HISTORY_MENU_MAX_WIDTH = 200

-- Truncated-command tooltip width; long commands wrap at it.
local HISTORY_TOOLTIP_WIDTH = 400

-- Horizontal text padding inside CodeEditBox (left, right).
local CODE_TEXT_INSET_LEFT = 4
local CODE_TEXT_INSET_RIGHT = 6

-- Shared inset so the code area's corner buttons line up.
local OVERLAY_INSET = 4

-- Fallbacks for a theme without toolIcons.inset/alpha or prompt.offset.
local TOOL_ICON_INSET, PROMPT_OFFSET = { x = 6, y = 4 }, { x = 10, y = 0 }
local TOOL_ICON_ALPHA = 0.6

-- Breathing room on whichever axis shrinks when clamped to screen.
local SCREEN_MARGIN = 100

-- Configure() fallbacks for settings the DB doesn't hold.
local DEFAULTS = {
  wrapText = false,
}

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_CodeEditorGutterChild : Frame
--- @field Numbers EditBox @Read-only "1\n2\n...\nN" in the code font, padded to a common digit width

--- @class LDK_CodeEditorGutter : ScrollFrame
--- @field ScrollChild LDK_CodeEditorGutterChild

--- @class LDK_MenuButton : Button
--- @field Label FontString
--- @field MouseoverOverlay Texture

--- @class LDK_CodeEditorBottomBar : Frame
--- @field WrapCheckButton CheckButton

--- @class LDK_CodeEditorCommandBar : Frame, BackdropTemplate
--- @field Prompt FontString
--- @field CommandEditBox EditBox @Single-line quick-eval input with Up/Down history
--- @field HistoryButton DropdownButton

--- @class LDK_CodeEditorOutputScrollChild : Frame
--- @field EvalStatus EditBox @Read-only output log; an EditBox so text can be selected and copied

--- @class LDK_CodeEditorOutputScrollFrame : ScrollFrame
--- @field ScrollChild LDK_CodeEditorOutputScrollChild @Floored at viewport height to keep output bottom-aligned

--- @class LDK_CodeEditorStatusBar : Frame, BackdropTemplate
--- @field OutputScrollFrame LDK_CodeEditorOutputScrollFrame @Clips the output box; wheel-scrolled, no scrollbar
--- @field ConsoleSettingsButton DropdownButton
--- @field ClearOutputButton Button

--- @class LDK_CodeEditorStatusDivider : Button
--- @field owner LDK_CodeEditorDialog
--- @field Grip Texture           @The draggable handle, colored by ApplyTheme
--- @field MaximizeButton Button
--- @field MinimizeButton Button
--- @field RunButton Button
--- @field cursorStart number|nil @Screen Y at drag start
--- @field heightStart number|nil @StatusBar height at drag start

--- @class LDK_CodeEditorHeaderTitle : Frame
--- @field Text FontString

--- @class LDK_CodeEditorHeaderCloseFrame : Frame
--- @field CloseButton Button

--- @class LDK_CodeEditorHeader : Frame, BackdropTemplate
--- @field Title LDK_CodeEditorHeaderTitle
--- @field CloseFrame LDK_CodeEditorHeaderCloseFrame

--- @class LDK_CodeEditorFontSteppers : Frame
--- @field MinusButton Button
--- @field PlusButton Button

--- @class LDK_CodeEditorWrapMeasure : Frame
--- @field Text FontString @Hidden; same font/wrap as CodeEditBox, used to count wrapped rows

--- @class LDK_CodeEditorDocStepper : Frame
--- @field Dropdown DropdownButton
--- @field DecrementButton Button
--- @field IncrementButton Button

--- @class LDK_CommandHistoryEntry
--- @field text string
--- @field failed boolean? @Last run hit a compile or runtime error

--- @class LDK_CodeEditorDialogMixin : Frame, BackdropTemplate, AceEvent-3.0
--- @field Header LDK_CodeEditorHeader                       @Title bar; carries drag-to-move
--- @field TopBar Frame                                      @Toolbar: document controls left, dropdowns right
--- @field OptionsButton DropdownButton                      @Alias of Header.OptionsButton
--- @field ThemeButton DropdownButton                        @Alias of TopBar.ThemeButton
--- @field FontButton DropdownButton                         @Alias of TopBar.FontButton
--- @field FontSizeButton DropdownButton                     @Alias of TopBar.FontSizeButton
--- @field NewButton Button                                  @Alias of TopBar.NewButton
--- @field SaveButton Button                                 @Alias of TopBar.SaveButton
--- @field DeleteButton Button                               @Alias of TopBar.DeleteButton
--- @field DocStepper LDK_CodeEditorDocStepper               @Alias of TopBar.DocStepper
--- @field docIndex number?                                  @DocumentStore index being edited; nil before the first
--- @field dirtyShown boolean?                               @Dirty state the document menu last showed
--- @field topBarHeight number                               @TopBar height to restore after a collapse
--- @field codeFont Font
--- @field fontFamily string                                 @Key of the currently applied font (see FontUtil:GetFontChoices())
--- @field fontSize number                                   @Snapped to FontUtil:GetFontSizes()
--- @field consoleFontFamily string?                         @nil follows fontFamily
--- @field consoleFontSize number?                           @nil follows fontSize
--- @field BottomBar LDK_CodeEditorBottomBar
--- @field CommandBar LDK_CodeEditorCommandBar
--- @field CommandEditBox EditBox                            @Alias of CommandBar.CommandEditBox
--- @field HistoryButton DropdownButton                      @Alias of CommandBar.HistoryButton
--- @field HistoryTooltip GameTooltip                        @History menu's own tooltip; shows truncated commands
--- @field commandHistory LDK_CommandHistoryEntry[]          @Alias of global.console.history
--- @field historyIndex number                               @Up/Down position; one past the end is the draft
--- @field historyDraft string?                              @Unsent text saved when stepping into history
--- @field StatusBar LDK_CodeEditorStatusBar                 @Output panel
--- @field StatusDivider LDK_CodeEditorStatusDivider         @Drag handle that sets StatusBar's height
--- @field OutputScrollFrame LDK_CodeEditorOutputScrollFrame @Alias of StatusBar.OutputScrollFrame
--- @field EvalStatus EditBox                                @Alias of StatusBar.OutputScrollFrame.ScrollChild.EvalStatus
--- @field ConsoleSettingsButton DropdownButton              @Alias of StatusBar.ConsoleSettingsButton
--- @field ClearOutputButton Button                          @Alias of StatusBar.ClearOutputButton
--- @field output LDK_OutputLog                              @Evaluation output, capped at MAX_OUTPUT_LINES
--- @field WrapMeasure LDK_CodeEditorWrapMeasure
--- @field wrapText boolean
--- @field GutterBackdrop Frame|BackdropTemplate             @Draws the gutter's border; Gutter is inset inside it
--- @field Gutter LDK_CodeEditorGutter
--- @field CodeBackdrop Frame|BackdropTemplate               @Draws the code area's border; ScrollFrame is inset inside it
--- @field ScrollFrame ScrollFrame
--- @field CodeEditBox LDK_CodeEditBox
--- @field CloseButton Button
--- @field SizerSE Frame                                     @Bottom-right resize grip
--- @field FontSteppers LDK_CodeEditorFontSteppers           @Floating +/- over the code area's top right
--- @field Border Frame|BackdropTemplate                     @Main edge art; draws over StatusBar and CommandBar
--- @field HeaderTitle FontString
--- @field borderStyle Name
--- @field statusGripColor RGBA                              @Resting divider grip color, from the active theme
--- @field statusGripHoverColor RGBA                         @Hovered divider grip color, from the active theme
LDK_CodeEditorDialogMixin = ns:NewAceEvent()
local o = LDK_CodeEditorDialogMixin

--
--- @class LDK_CodeEditorDialog : LDK_CodeEditorDialogMixin
--

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Called lazily: building fonts at file load may fail SetFont.
--- @return string @Key of the first font the client locale can render
local function DefaultFontFamily() return fut:GetDefaultFontChoice().key end

--- Falls back if the key no longer resolves (e.g. a removed font family).
--- @param key string
--- @return string
local function ResolveFontFamily(key) return fut:FindFontChoice(key) and key or DefaultFontFamily() end

--- Copy of a backdrop without one of its pieces.
--- @param bd LDK_Backdrop
--- @param key 'bgFile'|'edgeFile'
--- @return LDK_Backdrop
local function Omit(bd, key)
  local copy = CopyTable(bd) --[[@as LDK_Backdrop ]]
  copy[key] = nil
  return copy
end

--- Gates resize/refresh so no-op WoW size/text events don't self-feed.
--- @param current number|nil
--- @param wanted number
--- @return boolean
local function SizeDiffers(current, wanted) return math.abs((current or 0) - wanted) > 0.5 end

--- @param self LDK_CodeEditorDialog
--- @return number
local function CountLines(self)
  local text = self.CodeEditBox:GetText() or ''
  local _, count = text:gsub('\n', '\n')
  return count + 1
end

--- Lines that fit in one viewport, for Page Up/Down: floor(viewport height /
--- line height), so a page-jump moves exactly as far as what's currently
--- visible. Cmd+Page Up/Down jumps twice that.
--- @param self LDK_CodeEditorDialog
--- @return number
local function ViewportLines(self)
  return math.max(
    1,
    math.floor(self.ScrollFrame:GetHeight() / self.WrapMeasure.Text:GetLineHeight())
  )
end

--- Moves the caret `lines` lines up/down from its current position, landing
--- at the end of the target line. EditBox only exposes a flat character
--- offset (GetCursorPosition/SetCursorPosition), with no line-based cursor
--- API, so this walks '\n' boundaries one at a time from the current offset
--- -- at most `lines` lookups per press, not a full-document scan or line
--- table.
--- FAIAP.coloredGetText, not editBox:GetText(): once colorization is enabled,
--- GetText is overridden to return decoded (color-code-stripped) text, but
--- GetCursorPosition/SetCursorPosition operate on the raw text underneath
--- (full of |cRRGGBBAA...|r codes) -- walking '\n' positions in the shorter
--- decoded text and feeding them to SetCursorPosition as raw offsets would
--- land short of the real target line, the same mismatch Cmd+End hit.
--- coloredGetText calls the original, un-overridden GetText FAIAP captured
--- before replacing it, so this gets the real raw text either way.
--- @param self LDK_CodeEditorDialog
--- @param direction 1|-1
--- @param lines number
local function PageMoveCursor(self, direction, lines)
  local editBox = self.CodeEditBox
  local text = FAIAP.coloredGetText(editBox)
  local pos = editBox:GetCursorPosition()
  local crossed = 0

  for _ = 1, lines do
    if direction > 0 then
      local nl = text:find('\n', pos + 1, true)
      if not nl then
        pos = #text
        break
      end
      pos = nl
    else
      -- Land on '\n' itself, like the forward branch.
      local nl
      for p in text:sub(1, pos - 1):gmatch('()\n') do
        nl = p
      end
      if not nl then
        pos = 0
        break
      end
      pos = nl
    end
    crossed = crossed + 1
  end

  editBox:SetCursorPosition(pos)

  -- Scroll by `crossed` lines to keep the caret's viewport row unchanged.
  local scrollFrame = self.ScrollFrame
  local lineHeight = self.WrapMeasure.Text:GetLineHeight()
  local target = scrollFrame:GetVerticalScroll() + direction * crossed * lineHeight
  local maxScroll = scrollFrame:GetVerticalScrollRange()
  target = math.max(0, math.min(target, maxScroll))
  if SizeDiffers(scrollFrame:GetVerticalScroll(), target) then
    scrollFrame:SetVerticalScroll(target)
    self.Gutter:SetVerticalScroll(target)
  end
end

--- First MAX_LINES lines of text, or all of it when already shorter.
--- @param text string
--- @return string
local function TrimToMaxLines(text)
  local kept, count = {}, 0
  for line in TU:Lines(text) do
    count = count + 1
    if count > MAX_LINES then break end
    kept[count] = line
  end
  return table.concat(kept, '\n')
end

--- Digit width the gutter is sized for, and the width line numbers are padded
--- to. This padding, not justification, is what lines the column up: the box
--- is LEFT justified, so every row starts at the same x, and equal character
--- counts in a monospace font put every row's last digit at the same x too.
---
--- RIGHT justification looks equivalent but is not. It places each line at
--- (text area right minus that line's width), and a font whose advance is not
--- a whole number of pixels at the current size makes that width fractional:
--- JetBrains Mono and PT Mono are 0.6em (8.4px at size 14), so the remainder
--- cycles with the digit count and each line's right edge rounds to a
--- different pixel, leaving the column visibly ragged. Ubuntu Mono (0.5em) and
--- the Noto CJK faces (1.0em) are whole pixels, which is why only some fonts
--- showed it. LEFT plus padding never computes a line width, so the problem
--- cannot arise in any font at any size.
--- @param lastLine number Highest line number the gutter shows
--- @return number
local function GutterDigits(lastLine) return math.max(#tostring(lastLine), MIN_GUTTER_DIGITS) end

--- @param numLines number
--- @param digits number Width each number is padded to (see GutterDigits)
--- @return string text "  1\n  2\n...\n999"
--- @return number rows Rendered row count, for sizing the gutter
local function LineNumbersText(numLines, digits)
  local fmt = '%' .. digits .. 'd'
  local parts = {}
  for i = 1, numLines do
    parts[i] = fmt:format(i)
  end
  return table.concat(parts, '\n'), numLines
end

--- Wrap mode: pads each number with blank lines to mirror wrapped rows.
--- @param self LDK_CodeEditorDialog
--- @param digits number Width each number is padded to (see GutterDigits)
--- @return string text
--- @return number rows Rendered row count, for sizing the gutter
local function WrappedLineNumbersText(self, digits)
  local measure = self.WrapMeasure.Text
  local fmt = '%' .. digits .. 'd'
  local parts = {}
  local n = 0
  for line in TU:Lines(self.CodeEditBox:GetText()) do
    n = n + 1
    parts[#parts + 1] = fmt:format(n)
    measure:SetText(line)
    local rows = measure:GetNumLines()
    for _ = 2, rows do
      parts[#parts + 1] = ''
    end
  end
  return table.concat(parts, '\n'), #parts
end

--- GutterBackdrop width that fits the highest line number.
--- @param self LDK_CodeEditorDialog
--- @param lastLine number Highest line number the gutter shows
--- @return number
local function GutterWidth(self, lastLine)
  local measure = self.WrapMeasure.Text
  measure:SetText(string.rep('0', GutterDigits(lastLine)))
  -- Generous slack: too narrow truncates the EditBox at "...".
  return math.ceil(measure:GetStringWidth()) + GUTTER_SLACK + GUTTER_PADDING
end

--- Tallest StatusBar that still leaves MIN_CODE_HEIGHT for the code area.
--- @param self LDK_CodeEditorDialog
--- @return number @math.huge before the first layout: no cap yet
local function MaxStatusHeight(self)
  local top, bottom = self.TopBar:GetBottom(), self.BottomBar:GetTop()
  if not top or not bottom then return math.huge end
  return math.max(
    MIN_STATUS_HEIGHT,
    top - bottom - STATUS_DIVIDER_HEIGHT - COMMAND_BAR_HEIGHT - MIN_CODE_HEIGHT
  )
end

--- @param frame Frame
--- @param key string                    @Locale key of the label; the description is key .. '::Desc'
--- @param hintKey (fun(): string) | nil @Returns a locale key for a green instruction line
local function ShowTooltip(frame, key, hintKey)
  GameTooltip_SetDefaultAnchor(GameTooltip, frame)
  GameTooltip_SetTitle(GameTooltip, L[key])
  GameTooltip_AddNormalLine(GameTooltip, L[key .. '::Desc'])
  if hintKey then GameTooltip_AddInstructionLine(GameTooltip, L[hintKey()]) end
  GameTooltip:Show()
end

--- Standard hover tooltip; hooked so it composes with a frame's own OnEnter.
--- @param frame Frame
--- @param key string                    @Locale key of the label; the description is key .. '::Desc'
--- @param hintKey (fun(): string) | nil @Re-evaluated on every show; see ShowTooltip
--- @return fun()                        @Redraws the tooltip if it is showing for frame
local function AddTooltip(frame, key, hintKey)
  local function show() ShowTooltip(frame, key, hintKey) end
  frame:HookScript('OnEnter', show)
  frame:HookScript('OnLeave', function() GameTooltip:Hide() end)
  return function()
    if GameTooltip:IsOwned(frame) then show() end
  end
end

--- Keeps an arrow dropdown's glyph at `size`; each state resets it.
--- @param button DropdownButton
--- @param size number
local function PinArrowSize(button, size)
  local arrow = button.Arrow
  if not arrow then return end
  local function SizeArrow() arrow:SetSize(size, size) end
  SizeArrow()
  hooksecurefunc(arrow, 'SetAtlas', SizeArrow)
end

--- @param button DropdownButton
--- @param menus Frame[] @The open menu and its submenus
--- @return boolean
local function IsMouseOverMenu(button, menus)
  if button:IsMouseOver() then return true end
  for _, menu in ipairs(menus) do
    if menu:IsShown() and menu:IsMouseOver() then return true end
  end
  return false
end

--- Closes the menu once the mouse is off it, its submenus and the button.
--- @param button DropdownButton
local function CloseMenuOnLeave(button)
  local ticker
  local function stop()
    if ticker then ticker:Cancel() end
    ticker = nil
  end
  button:RegisterCallback(DropdownButtonMixin.Event.OnMenuOpen, function()
    stop()
    local menus, away = { Menu.GetManager():GetOpenMenu() }, 0
    -- Submenus share the root's callbacks, so this sees each one open.
    button:GetMenuDescription():AddMenuAcquiredCallback(function(menu) menus[#menus + 1] = menu end)
    ticker = C_Timer.NewTicker(MENU_LEAVE_POLL, function()
      away = IsMouseOverMenu(button, menus) and 0 or away + MENU_LEAVE_POLL
      if away >= MENU_LEAVE_DELAY then button:CloseMenu() end
    end)
  end, button)
  button:RegisterCallback(DropdownButtonMixin.Event.OnMenuClose, stop, button)
end

--- Runs after Blizzard's SetTextToFit, which sizes text to fit.
--- @param button Button @Menu row with a fontString
local function CapHistoryRowWidth(button)
  local text = button.fontString
  text:SetWidth(math.min(text:GetWidth(), HISTORY_MENU_MAX_WIDTH))
end

--- Full command in a tooltip, only when the row cut it short.
--- @param frame Button @Menu row
--- @param row ElementMenuDescriptionProxy
--- @param label string
--- @param font Font    @Editor's code font
local function ShowTruncatedCommand(frame, row, label, font)
  if not frame.fontString:IsTruncated() then return end
  MenuUtil.ShowTooltipEx(frame, row:GetTooltipFrame(), function(tooltip)
    tooltip:SetMinimumWidth(HISTORY_TOOLTIP_WIDTH)
    tooltip.TextLeft1:SetFontObject(font)
    GameTooltip_AddHighlightLine(tooltip, label, true)
  end)
end

--- Radio submenu led by Same as Editor, whose value is nil.
--- @param root RootMenuDescriptionProxy
--- @param key string                     @Locale key of the submenu label
--- @param items { label: string, value: any }[]
--- @param getValue fun(): any
--- @param setValue fun(value: any)
local function AddConsoleSubmenu(root, key, items, getValue, setValue)
  local menu = root:CreateButton(L[key])
  local function isSelected(value) return value == getValue() end
  menu:CreateRadio(L['Same as Editor'], isSelected, setValue)
  for _, item in ipairs(items) do
    menu:CreateRadio(item.label, isSelected, setValue, item.value)
  end
end

--- CCW radians; bag-arrow art points left, so pi/2 = down, -pi/2 = up.
--- @param button Button
--- @param radians number
local function RotateArrow(button, radians)
  button:GetNormalTexture():SetRotation(radians)
  button:GetPushedTexture():SetRotation(radians)
  button:GetDisabledTexture():SetRotation(radians)
  button:GetHighlightTexture():SetRotation(radians)
end

--- @return string @Locale key naming this client's run shortcut
local function RunHintKey() return IsMacClient() and 'Run::Hint::Mac' or 'Run::Hint' end

--- Enables an arrow button, or disables and dims it.
--- @param button Button
--- @param enabled boolean
local function UpdateArrowState(button, enabled)
  button:SetEnabled(enabled)
  button:SetAlpha(enabled and ARROW_ENABLED_ALPHA or ARROW_DISABLED_ALPHA)
end

--- Width the EditBox actually wraps text at: viewport minus its text insets.
--- @param self LDK_CodeEditorDialog
--- @return number
local function CodeTextWidth(self)
  local left, right = self.CodeEditBox:GetTextInsets()
  return self.ScrollFrame:GetWidth() - left - right
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
function o:OnLoad()
  self.CodeEditBox = self.ScrollFrame.CodeEditBox
  self.OutputScrollFrame = self.StatusBar.OutputScrollFrame
  self.EvalStatus = self.OutputScrollFrame.ScrollChild.EvalStatus
  self.ConsoleSettingsButton = self.StatusBar.ConsoleSettingsButton
  self.ClearOutputButton = self.StatusBar.ClearOutputButton
  self.CommandEditBox = self.CommandBar.CommandEditBox
  self:_RegisterMessages()
end

function o:Initialize()
  self:UnregisterMessage(ns:msg('OnEnable'))
  self.output = OutputLog:New(MAX_OUTPUT_LINES)

  self:OnLoad_Viewports()
  self:OnLoad_Overlays()
  self:OnLoad_GripLines()
  self:OnLoad_EditBoxScrollBar()

  ns:EnableLuaFormatter(self.CodeEditBox)

  local numbers = self.Gutter.ScrollChild.Numbers

  -- SetEnabled is the real read-only switch, not enableKeyboard.
  numbers:SetEnabled(false)
  -- LEFT, not RIGHT: the numbers are padded to a common width (see GutterDigits).
  numbers:SetJustifyH('LEFT')
  -- TOP keeps row 1 at the top when the box is taller than its text (short files).
  numbers:SetJustifyV('TOP')
  numbers:SetTextInsets(0, GUTTER_TEXT_RIGHT_INSET, 0, 0)

  self:OnLoad_Border()

  self:ConfigureEditor(ns:editor())

  if self.SetResizeBounds then -- WoW 10.0+
    self:SetResizeBounds(400, 250)
  else
    self:SetMinResize(400, 250)
  end

  self:OnLoad_ScaleWatcher()
  self:OnLoad_Header()
  self:OnLoad_Toolbar()
  self:OnLoad_FontSteppers()
  self:OnLoad_WrapCheckButton()
  self:OnLoad_RunButton()
  self:OnLoad_CodeEditBox()
  self:OnLoad_StatusBar()
  self:OnLoad_CommandBar()
  self:OnLoad_MenuAutoClose()
  self:OnLoad_UnsavedPrompt()
  self:OnLoad_NamePrompt()
  self:OnLoad_DeletePrompt()

  -- After OnLoad_Toolbar: the stepper menu must exist.
  self:LoadDocuments()

  self:RefreshGutter()
  self:Configure()
end

--- After the OnLoad_* steps that alias each menu button.
function o:OnLoad_MenuAutoClose()
  local buttons = {
    self.OptionsButton,
    self.ThemeButton,
    self.FontButton,
    self.FontSizeButton,
    self.DocStepper.Dropdown,
    self.HistoryButton,
    self.ConsoleSettingsButton,
  }
  for _, button in ipairs(buttons) do
    CloseMenuOnLeave(button)
  end
end

--- The prompt's data is the switch to run after Save or Discard.
function o:OnLoad_UnsavedPrompt()
  StaticPopupDialogs[UNSAVED_PROMPT] = {
    text = L['Save changes to "%s"?'],
    button1 = L['Save'],
    button2 = L['Cancel'],
    button3 = L['Discard'],
    selectCallbackByIndex = true,
    OnButton1 = function(_, proceed)
      self:SaveDocument()
      proceed()
    end,
    -- Without a handler the button wouldn't hide the prompt.
    OnButton2 = function() end,
    OnButton3 = function(_, proceed) proceed() end,
    hideOnEscape = true,
    timeout = 0,
    whileDead = true,
    preferredIndex = 3,
  }
end

--- The prompt's data is a LDK_DocNamePromptData.
function o:OnLoad_NamePrompt()
  --- @param data LDK_DocNamePromptData
  local function accept(box, data)
    local name = strtrim(box:GetText())
    if name ~= '' then data.onAccept(name) end
  end
  StaticPopupDialogs[NAME_PROMPT] = {
    text = '%s',
    button1 = L['Save'],
    button2 = L['Cancel'],
    hasEditBox = true,
    maxLetters = DOC_NAME_MAX_LETTERS,
    OnShow = function(dialog, data)
      local box = dialog:GetEditBox()
      box:SetText(data.name)
      box:SetFocus()
      box:HighlightText()
    end,
    OnAccept = function(dialog, data) accept(dialog:GetEditBox(), data) end,
    EditBoxOnEnterPressed = function(box, data)
      local dialog = box:GetParent()
      if not dialog:GetButton1():IsEnabled() then return end
      accept(box, data)
      dialog:Hide()
    end,
    EditBoxOnTextChanged = StaticPopup_StandardNonEmptyTextHandler,
    EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
    hideOnEscape = true,
    timeout = 0,
    whileDead = true,
    preferredIndex = 3,
  }
end

--- The prompt's data is the index of the document to delete.
function o:OnLoad_DeletePrompt()
  StaticPopupDialogs[DELETE_PROMPT] = {
    text = L['Delete "%s"?'],
    button1 = L['Delete'],
    button2 = L['Cancel'],
    OnAccept = function(_, index) self:DeleteDocument(index) end,
    showAlert = true,
    hideOnEscape = true,
    timeout = 0,
    whileDead = true,
    preferredIndex = 3,
  }
end

function o:_RegisterMessages()
  -- Fonts and the DB are ready once LDK_CodeEditor enables.
  self:RegisterMessage(ns:msg('OnEnable'), 'Initialize')
end

--- Places both scroll viewports inside their backdrops. Anchored here rather
--- than in XML so the shared vertical inset lives in one place.
function o:OnLoad_Viewports()
  local v = VIEWPORT_TOP_BOTTOM_INSET
  self.Gutter:SetPoint('TOPLEFT', self.GutterBackdrop, 'TOPLEFT', 5, -v)
  self.Gutter:SetPoint('BOTTOMRIGHT', self.GutterBackdrop, 'BOTTOMRIGHT', -4, v)
  self.ScrollFrame:SetPoint('TOPLEFT', self.CodeBackdrop, 'TOPLEFT', 2, -v)
  self.ScrollFrame:SetPoint('BOTTOMRIGHT', self.ScrollBarGap, 'BOTTOMRIGHT', -5, v)
  -- OutputScrollFrame is anchored in XML; see its comment.
end

--- Pins the floating buttons to the code area's right corners.
function o:OnLoad_Overlays()
  local i = OVERLAY_INSET
  self.FontSteppers:SetPoint('TOPRIGHT', self.ScrollFrame, 'TOPRIGHT', -(i - 2), -i)
  self.FontSteppers:SetAlpha(OVERLAY_ALPHA)
  self.StatusDivider.RunButton:SetPoint(
    'BOTTOMRIGHT',
    self.ScrollFrame,
    'BOTTOMRIGHT',
    -(i - 3.3),
    i
  )
  -- Above the output box, which would otherwise take their clicks.
  local level = self.EvalStatus:GetFrameLevel() + 1
  for _, button in ipairs({ self.ConsoleSettingsButton, self.ClearOutputButton }) do
    button:SetFrameLevel(level)
    button:SetAlpha(OVERLAY_ALPHA)
  end
end

--- Starts at viewport height for a clickable area; RefreshGutter grows it.
function o:OnLoad_CodeEditBox()
  self.CodeEditBox:SetHeight(self.ScrollFrame:GetHeight())
  self.CodeEditBox:SetAutoFocus(false)
  self:SetWrapText(DEFAULTS.wrapText)
  -- Insets pad text; top/bottom must stay 0 or line 1 desyncs from gutter.
  self.CodeEditBox:SetTextInsets(CODE_TEXT_INSET_LEFT, CODE_TEXT_INSET_RIGHT, 0, 0)
end

function o:OnLoad_WrapCheckButton()
  local button = self.BottomBar.WrapCheckButton
  button.text:SetText(L['Wrap Text'])
  button:SetHitRectInsets(0, -button.text:GetStringWidth(), 0, 0)
  AddTooltip(button, 'Wrap Text')
end

--- Play icon in the code area's corner; tooltip names the shortcut.
function o:OnLoad_RunButton()
  local button = self.StatusDivider.RunButton
  RotateArrow(button, math.pi)
  button.NormalTexture:SetVertexColor(RUN_ICON_COLOR:GetRGB())
  button:SetAlpha(OVERLAY_ALPHA)
  button:SetScript('OnClick', function() self:Run() end)
  AddTooltip(button, 'Run', RunHintKey)
end

function o:OnLoad_StatusBar()
  local divider = self.StatusDivider
  divider.MaximizeButton:SetScript('OnClick', function() self:MaximizeStatus() end)
  divider.MinimizeButton:SetScript('OnClick', function() self:MinimizeStatus() end)
  RotateArrow(divider.MinimizeButton, math.pi / 2)
  RotateArrow(divider.MaximizeButton, -math.pi / 2)
  AddTooltip(divider.MaximizeButton, 'Maximize Output')
  AddTooltip(divider.MinimizeButton, 'Minimize Output')
  self:OnLoad_DividerTooltip()
  self:OnLoad_EvalStatus()
  self:OnLoad_ConsoleSettingsButton()
  self:OnLoad_ClearOutputButton()
  self:ClearOutput()
end

function o:OnLoad_ClearOutputButton()
  local button = self.ClearOutputButton
  button:SetScript('OnClick', function() self:ClearOutput() end)
  AddTooltip(button, 'Clear Output')
end

function o:OnLoad_ConsoleSettingsButton()
  local button = self.ConsoleSettingsButton
  button:SetupMenu(function(_, root) self:BuildConsoleSettingsMenu(root) end)
  AddTooltip(button, 'Console Settings')
end

--- @param root RootMenuDescriptionProxy
function o:BuildConsoleSettingsMenu(root)
  local fonts, sizes = {}, {}
  for i, choice in ipairs(fut:GetFontChoices()) do
    fonts[i] = { label = choice.label, value = choice.key }
  end
  for i, size in ipairs(fut:GetFontSizes()) do
    sizes[i] = { label = tostring(size), value = size }
  end
  AddConsoleSubmenu(
    root,
    'Console Font',
    fonts,
    function() return self.consoleFontFamily end,
    function(key) self:SetConsoleFont(key, self.consoleFontSize) end
  )
  AddConsoleSubmenu(
    root,
    'Console Font Size',
    sizes,
    function() return self.consoleFontSize end,
    function(size) self:SetConsoleFont(self.consoleFontFamily, size) end
  )
end

--- Hint names what a double-click does next; refreshed while hovered.
function o:OnLoad_DividerTooltip()
  local divider = self.StatusDivider
  local refresh = AddTooltip(divider, 'Resize Output', function() return self:DividerHintKey() end)
  divider:HookScript('OnMouseUp', refresh)
  divider:HookScript('OnDoubleClick', refresh)
end

--- Wires the output box; RefreshOutput fills it.
function o:OnLoad_EvalStatus()
  local scrollFrame = self.OutputScrollFrame
  -- No enableMouseWheel attribute exists; UI.xsd has mouse only.
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript('OnMouseWheel', function(_, delta) self:ScrollOutput(delta) end)
  scrollFrame:SetScript('OnSizeChanged', function() self:RefreshOutput() end)
  scrollFrame:SetScript(
    'OnScrollRangeChanged',
    function(_, _, yRange) self:OnOutputScrollRangeChanged(yRange) end
  )
  self.EvalStatus:SetScript(
    'OnTextChanged',
    function(_, userInput) self:OnEvalStatusTextChanged(userInput) end
  )
  -- The box grows a frame after SetText; resize the child when it does.
  -- Safe to wire: this writes the child's height, never the box's.
  self.EvalStatus:SetScript('OnSizeChanged', function() self:SyncOutputHeight() end)
end

--- Append or resize; both should show the newest line.
--- @param yRange number
function o:OnOutputScrollRangeChanged(yRange) self.OutputScrollFrame:SetVerticalScroll(yRange) end

--- Read-only: the output log is the only text source.
--- @param userInput boolean
function o:OnEvalStatusTextChanged(userInput)
  if userInput then self:RefreshOutput() end
end

--- @param delta number Wheel direction, positive up
function o:ScrollOutput(delta)
  local scrollFrame = self.OutputScrollFrame
  local step = self.WrapMeasure.Text:GetLineHeight() * OUTPUT_SCROLL_LINES
  local target = scrollFrame:GetVerticalScroll() - delta * step
  scrollFrame:SetVerticalScroll(Clamp(target, 0, scrollFrame:GetVerticalScrollRange()))
end

--- Floating +/- over the code area; steps the font size.
function o:OnLoad_FontSteppers()
  local steppers = self.FontSteppers
  steppers:SetFrameLevel(self.CodeEditBox:GetFrameLevel() + 1)
  steppers.PlusButton:SetScript('OnClick', function() self:StepFontSize(1) end)
  steppers.MinusButton:SetScript('OnClick', function() self:StepFontSize(-1) end)
  AddTooltip(steppers.PlusButton, 'Increase Font Size')
  AddTooltip(steppers.MinusButton, 'Decrease Font Size')
end

--- Border over the panels; Header, TopBar, grip stay on top.
function o:OnLoad_Border()
  local level = self.StatusBar:GetFrameLevel() + 1
  self.Border:SetFrameLevel(level)
  self.Header:SetFrameLevel(level + 1)
  self.TopBar:SetFrameLevel(level + 1)
  self.SizerSE:SetFrameLevel(level + 1)
end

--- Panels start where the main bg does; Border hides their sides.
--- @param insets LDK_Insets|nil Main backdrop insets
function o:InsetPanels(insets)
  local left = insets and insets.left or 0
  local right = insets and insets.right or 0
  local bar = self.CommandBar
  bar:ClearAllPoints()
  bar:SetPoint('BOTTOMLEFT', self.BottomBar, 'TOPLEFT', left, 0)
  bar:SetPoint('BOTTOMRIGHT', self.BottomBar, 'TOPRIGHT', -right, 0)

  -- Divider stays full width; the code area anchors to it.
  local divider = self.StatusDivider
  divider:ClearAllPoints()
  divider:SetPoint('BOTTOMLEFT', self.StatusBar, 'TOPLEFT', -left, 0)
  divider:SetPoint('BOTTOMRIGHT', self.StatusBar, 'TOPRIGHT', right, 0)
end

--- Editable, unlike EvalStatus; native focus/keyboard.
function o:OnLoad_CommandBar()
  self.CommandBar.Prompt:SetText('▶ ')
  self.CommandEditBox:SetAutoFocus(false)
  self.commandHistory = ns:g().console.history
  self.historyIndex = #self.commandHistory + 1
  self.CommandEditBox:SetScript('OnArrowPressed', function(_, key) self:StepCommandHistory(key) end)
  AddTooltip(self.CommandEditBox, 'Command Line')
  self:OnLoad_HistoryButton()
end

function o:OnLoad_HistoryButton()
  local button = self.CommandBar.HistoryButton
  self.HistoryButton = button
  PinArrowSize(button, DROPDOWN_ARROW_SIZE)
  -- The command bar sits low; open the menu upward.
  button:SetMenuAnchor(AnchorUtil.CreateAnchor('BOTTOMRIGHT', button, 'TOPRIGHT'))
  button:SetupMenu(function(_, root) self:BuildHistoryMenu(root) end)
  AddTooltip(button, 'Command History')
  -- Own tooltip: its width and font never leak to GameTooltip.
  self.HistoryTooltip = CreateFrame(
    'GameTooltip',
    'LDK_CommandHistoryTooltip',
    UIParent,
    'SharedNoHeaderTooltipTemplate' --[[@as Template]]
  )
end

--- Newest first; picking an entry puts it back on the command line.
--- @param root RootMenuDescriptionProxy
function o:BuildHistoryMenu(root)
  local history = self.commandHistory
  if #history == 0 then
    root:CreateTitle(L['No Command History'])
    return
  end
  root:SetScrollMode(HISTORY_MENU_MAX_HEIGHT)
  root:SetTooltipFrame(self.HistoryTooltip)
  for i = #history, 1, -1 do
    local entry = history[i]
    -- Escape '|' so a command can't render as a color/texture code.
    local plain = entry.text:gsub('|', '||')
    local label = entry.failed and RED_FONT_COLOR:WrapTextInColorCode(plain) or plain
    local row = root:CreateButton(label, function() self:RecallCommand(i) end)
    row:AddInitializer(CapHistoryRowWidth)
    row:SetOnEnter(
      function(frame) ShowTruncatedCommand(frame, row, self:SyntaxColor(plain), self.codeFont) end
    )
  end
end

--- Same colors as the code editor; plain if FAIAP isn't loaded.
--- @param text string @Escaped, as FAIAP sees editor text
--- @return string
function o:SyntaxColor(text)
  local colors = self.CodeEditBox.faiap_colorTable
  if not colors then return text end
  return (FAIAP.colorCodeCode(text, colors))
end

--- @param index number @Position in commandHistory
function o:RecallCommand(index)
  self:SaveCommandDraft()
  self.historyIndex = index
  self.CommandEditBox:SetText(self.commandHistory[index].text)
  self.CommandEditBox:SetFocus()
end

--- @param key 'UP'|'DOWN'|'LEFT'|'RIGHT'
function o:StepCommandHistory(key)
  local history = self.commandHistory
  local step = (key == 'UP' and -1) or (key == 'DOWN' and 1)
  if not step or #history == 0 then return end
  self:SaveCommandDraft()
  self.historyIndex = Clamp(self.historyIndex + step, 1, #history + 1)
  local entry = history[self.historyIndex]
  self.CommandEditBox:SetText(entry and entry.text or self.historyDraft or '')
end

--- Keeps unsent text when leaving the draft slot for history.
function o:SaveCommandDraft()
  if self.historyIndex ~= #self.commandHistory + 1 then return end
  self.historyDraft = self.CommandEditBox:GetText()
end

--- A repeat of the last command updates it instead of adding.
--- @param text string
--- @param failed boolean
function o:PushCommandHistory(text, failed)
  local history = self.commandHistory
  local last = history[#history]
  if last and last.text == text then
    last.failed = failed or nil
  else
    table.insert(history, { text = text, failed = failed or nil })
  end
  if #history > MAX_COMMAND_HISTORY then table.remove(history, 1) end
  self.historyIndex, self.historyDraft = #history + 1, nil
end

--- A too-wide dialog must shrink to fit; clampedToScreen can't move it in.
function o:OnLoad_ScaleWatcher()
  self.ScaleWatcher = CreateFrame('Frame')
  self.ScaleWatcher:RegisterEvent('UI_SCALE_CHANGED')
  self.ScaleWatcher:RegisterEvent('DISPLAY_SIZE_CHANGED')
  self.ScaleWatcher:SetScript('OnEvent', function() self:ClampToScreen(true) end)
end

--- Title, close button and the Options menu.
function o:OnLoad_Header()
  local header = self.Header
  self.HeaderTitle = header.Title.Text
  self.HeaderTitle:SetText('Code Editor (Prototype)')

  self.CloseButton = header.CloseFrame.CloseButton
  -- Wired in Lua: inherited OnClick hides CloseFrame, not the dialog.
  self.CloseButton:SetScript('OnClick', function() self:OnClickClose() end)

  self.OptionsButton = header.OptionsButton
  self.OptionsButton:SetupMenu(function(_, root) self:BuildOptionsMenu(root) end)
  self:OnLoad_OptionsButton()
end

function o:OnLoad_OptionsButton() PinArrowSize(self.OptionsButton, DROPDOWN_ARROW_SIZE) end

--- @param root RootMenuDescriptionProxy
function o:BuildOptionsMenu(root)
  local function isSaveOnRun() return ns:editor().saveOnRun end
  root:CreateCheckbox(L['Save on Run'], isSaveOnRun, function() self:ToggleSaveOnRun() end)
  local function isToolbarShown() return self.TopBar:IsShown() end
  root:CreateCheckbox(L['Show Toolbar'], isToolbarShown, function() self:ToggleToolbar() end)
end

function o:OnLoad_ThemeButton()
  --- @param rootDescription RootMenuDescriptionProxy
  self.ThemeButton:SetupMenu(function(_, rootDescription)
    local function addRadio(name)
      rootDescription:CreateRadio(
        name,
        function() return name and str_eq(self.borderStyle, name) end,
        function() self:ApplyTheme(name, true) end
      )
    end
    bdrops:EachTheme(addRadio, function(name) return name and name:lower() ~= 'none' end)
  end)
  -- Theme names are registry keys, so menu entries stay untranslated.
  AddTooltip(self.ThemeButton, 'Theme')
end

--- Every TopBar control; OnLoad_ToolbarEdges needs their aliases.
function o:OnLoad_Toolbar()
  local bar = self.TopBar
  self.ThemeButton = bar.ThemeButton
  self.FontButton = bar.FontButton
  self.FontSizeButton = bar.FontSizeButton
  self:OnLoad_ThemeButton()
  self:OnLoad_Fonts()
  self:OnLoad_NewButton()
  self:OnLoad_SaveButton()
  self:OnLoad_DeleteButton()
  self:OnLoad_DocStepper()
  self:OnLoad_ToolbarEdges()
  self:OnLoad_ToolbarIcons()
end

--- Strips dropdown chrome so only the icon art shows.
function o:OnLoad_ToolbarIcons()
  for _, button in ipairs(self:RightToolbarIcons()) do
    button.Background:Hide()
    button.Arrow:Hide()
    button.Text:Hide()
  end
  self:LayoutToolbar(TOOLBAR_ICON_SIZE, TOOLBAR_ICON_GAP)
end

--- @return DropdownButton[] @Right to left, ThemeButton first
function o:RightToolbarIcons() return { self.ThemeButton, self.FontButton, self.FontSizeButton } end

--- Sizes the icons and fits the stepper and bar height to them.
--- @param size number
--- @param gap number
function o:LayoutToolbar(size, gap)
  self:LayoutToolbarIcons(size, gap)
  self:LayoutDocStepper(size - DOC_DROPDOWN_INSET, gap)
  self.topBarHeight = size + TOOLBAR_ICON_LIFT + TOOLBAR_TOP_PAD
  if self.TopBar:IsShown() then self.TopBar:SetHeight(self.topBarHeight) end
end

--- Sizes the icon buttons and chains the right-side ones leftward.
--- Snapped to whole pixels so every gap rounds the same way.
--- @param size number
--- @param gap number
function o:LayoutToolbarIcons(size, gap)
  PixelUtil.SetSize(self.NewButton, size, size)
  PixelUtil.SetSize(self.SaveButton, size, size)
  PixelUtil.SetSize(self.DeleteButton, size, size)
  PixelUtil.SetPoint(self.SaveButton, 'LEFT', self.NewButton, 'RIGHT', gap, 0)
  PixelUtil.SetPoint(self.DeleteButton, 'LEFT', self.SaveButton, 'RIGHT', gap, 0)
  local prev
  for _, button in ipairs(self:RightToolbarIcons()) do
    PixelUtil.SetSize(button, size, size)
    if prev then PixelUtil.SetPoint(button, 'RIGHT', prev, 'LEFT', -gap, 0) end
    prev = button
  end
end

function o:OnLoad_NewButton()
  self.NewButton = self.TopBar.NewButton
  self.NewButton:SetScript('OnClick', function() self:NewDocument() end)
  AddTooltip(self.NewButton, 'New Document')
end

function o:OnLoad_SaveButton()
  self.SaveButton = self.TopBar.SaveButton
  self.SaveButton:SetScript('OnClick', function() self:SaveDocument() end)
  AddTooltip(self.SaveButton, 'Save Document')
end

function o:OnLoad_DeleteButton()
  self.DeleteButton = self.TopBar.DeleteButton
  self.DeleteButton:SetScript('OnClick', function() self:PromptDeleteDocument() end)
  AddTooltip(self.DeleteButton, 'Delete Document')
end

function o:OnLoad_DocStepper()
  self.DocStepper = self.TopBar.DocStepper
  local dropdown = self.DocStepper.Dropdown
  dropdown:SetupMenu(function(_, root) self:BuildDocumentMenu(root) end)
  dropdown:HookScript('OnMouseDown', function(_, button) self:OnDocDropdownMouseDown(button) end)
  AddTooltip(dropdown, 'Open Document', function() return 'Open Document::Hint' end)
end

--- Shift-click renames, alt-click saves as; the menu stays shut.
--- @param button string
function o:OnDocDropdownMouseDown(button)
  if button ~= 'LeftButton' then return end
  local action = (IsShiftKeyDown() and self.PromptRenameDocument)
    or (IsAltKeyDown() and self.PromptSaveDocumentAs)
  if not action then return end
  -- An alt-click reaches here after the dropdown opened its menu.
  self.DocStepper.Dropdown:CloseMenu()
  action(self)
end

--- Chains the back arrow and dropdown off DeleteButton by `gap`.
--- @param height number
--- @param gap number
function o:LayoutDocStepper(height, gap)
  local stepper = self.DocStepper
  local back, dropdown = stepper.DecrementButton, stepper.Dropdown
  PixelUtil.SetSize(dropdown, DOC_DROPDOWN_WIDTH, height)
  -- Arrow art resets to atlas size per state; scale it instead.
  for _, arrow in ipairs({ back, stepper.IncrementButton }) do
    arrow:SetScale(height / arrow:GetHeight())
  end
  -- Replaces the mixin's back-arrow anchor to the dropdown.
  back:ClearAllPoints()
  -- Offsets on a scaled frame scale too; divide it back out.
  PixelUtil.SetPoint(back, 'LEFT', self.DeleteButton, 'RIGHT', gap / back:GetScale(), 0)
  PixelUtil.SetPoint(dropdown, 'LEFT', back, 'RIGHT', -stepper.decrementOffsetX, 0)
end

--- Lines New and Theme up with the code area's top corners; the
--- stepper and font buttons chain off them. CodeBackdrop comes
--- later in the XML, so anchored here.
function o:OnLoad_ToolbarEdges()
  local code, lift = self.CodeBackdrop, TOOLBAR_ICON_LIFT
  self.NewButton:SetPoint('BOTTOMLEFT', code, 'TOPLEFT', 2, lift)
  self.ThemeButton:SetPoint('BOTTOMRIGHT', code, 'TOPRIGHT', 2, lift)
end

--- Collapses or restores the toolbar; the code area follows it.
--- @param shown boolean
function o:SetToolbarShown(shown)
  local bar = self.TopBar
  bar:SetShown(shown)
  -- Hidden frames keep their size; 1 not 0, which drops anchors.
  bar:SetHeight(shown and self.topBarHeight or 1)
  -- Re-clamp: the output panel's max height just changed.
  self:SetStatusHeight(self:GetStatusHeight())
end

function o:ToggleToolbar() self:SetToolbarShown(not self.TopBar:IsShown()) end

function o:OnLoad_Fonts()
  self.FontButton:SetupMenu(function(_, rootDescription)
    for _, choice in ipairs(fut:GetFontChoices()) do
      -- CreateButton never checks IsSelected() -- only CreateRadio draws
      -- a checkmark for the current selection.
      rootDescription:CreateRadio(
        choice.label,
        function() return self.fontFamily == choice.key end,
        function() self:SetCodeFont(choice.key, true) end
      )
    end
  end)
  self.FontSizeButton:SetupMenu(function(_, rootDescription)
    for _, size in ipairs(fut:GetFontSizes()) do
      rootDescription:CreateRadio(
        tostring(size),
        function() return self.fontSize == size end,
        function() self:SetFontSize(size, true) end
      )
    end
  end)
  AddTooltip(self.FontButton, 'Font Family')
  AddTooltip(self.FontSizeButton, 'Font Size')
end

--- Diagonal resize-grip lines
function o:OnLoad_GripLines()
  local line1 = self.SizerSE.Line1
  local x1 = 0.1 * 14 / 17
  local line1Origin = 0.05
  local line1Center = 0.1
  line1:SetTexCoord(
    line1Origin - x1,
    line1Center,
    line1Origin,
    line1Center + x1,
    line1Origin,
    line1Center - x1,
    line1Center + x1,
    line1Center
  )
  local line2 = self.SizerSE.Line2
  local x2 = 0.1 * 5 / 17
  local line2Origin = 0.032
  local line2Center = 0.40
  line2:SetTexCoord(
    line2Origin - x2,
    line2Center,
    line2Origin,
    line2Center + x2,
    line2Origin,
    line2Center - x2,
    line2Center + x2,
    line2Center
  )
end

function o:OnLoad_EditBoxScrollBar()
  local scrollBar = self.ScrollFrame.ScrollBar
  local up, down = ns.O.MinimalScrollBarStyle.Apply(scrollBar)

  -- Re-anchor scrollbar here; XML would need the whole template redeclared.
  -- Inset by stepper height, else it clips outside.
  scrollBar:ClearAllPoints()
  scrollBar:SetPoint('TOPLEFT', self.ScrollFrame, 'TOPRIGHT', 6, -up)
  scrollBar:SetPoint('BOTTOMLEFT', self.ScrollFrame, 'BOTTOMRIGHT', 6, down)
end

--- toplevel="true" only re-raises on click; this covers open-underneath too.
function o:OnShow()
  self:Raise()
  -- Scale may change while hidden; re-clamp visibly on the way in.
  self:ClampToScreen(true)
  self:SetStatusHeight(self:GetStatusHeight())
  -- SetFocus() needs the frame visible; OnLoad ran while still hidden.
  if not self.initialFocusApplied then
    self.initialFocusApplied = true
    -- todo: SetFocus() puts the cursor in the editbox
    -- turn off for now
    --self.CodeEditBox:SetFocus()
    self.CodeEditBox:SetCursorPosition(0)
  end
end

--- Shrinks and repositions the dialog to fit after a UI scale change.
--- @param withMargin boolean|nil Leave SCREEN_MARGIN of room on an axis that has to shrink; omit for a bare screen-edge clamp
function o:ClampToScreen(withMargin)
  local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
  local maxWidth, maxHeight = screenWidth, screenHeight
  local width, height = self:GetWidth(), self:GetHeight()
  -- withMargin centers a shrunk axis with room on each side, not flush.
  local insetX, insetY = 0, 0
  if withMargin then
    if width > maxWidth then
      maxWidth = maxWidth - SCREEN_MARGIN
      insetX = SCREEN_MARGIN / 2
    end
    if height > maxHeight then
      maxHeight = maxHeight - SCREEN_MARGIN
      insetY = SCREEN_MARGIN / 2
    end
  end
  -- Floors are the resize minimums; smaller isn't worth distorting for.
  local fitWidth = math.max(400, math.min(width, maxWidth))
  local fitHeight = math.max(250, math.min(height, maxHeight))
  if fitWidth ~= width or fitHeight ~= height then self:SetSize(fitWidth, fitHeight) end

  -- Re-anchor from the measured rect; StartMoving leaves an arbitrary point.
  local left, bottom = self:GetLeft(), self:GetBottom()
  if not left or not bottom then return end
  -- Half-margin held back so a shrunk axis keeps its gap, not pinned edge.
  local clampedLeft = math.max(insetX, math.min(left, screenWidth - fitWidth - insetX))
  local clampedBottom = math.max(insetY, math.min(bottom, screenHeight - fitHeight - insetY))
  if clampedLeft ~= left or clampedBottom ~= bottom then
    self:ClearAllPoints()
    self:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', clampedLeft, clampedBottom)
  end
end

--- Dialog resized; re-clamp status height in case it's now under the min.
function o:OnSizeChanged()
  -- Can fire mid-construction, before StatusBar/StatusDivider are aliased.
  if not self.StatusBar or not self.StatusDivider then return end
  self:SetStatusHeight(self.StatusBar:GetHeight())
end

function o:OnClickClose() self:Hide() end

--- @param key string
function o:OnKeyDown(key)
  if key == 'ESCAPE' then
    self:OnClickClose()
    self:SetPropagateKeyboardInput(false)
  else
    self:SetPropagateKeyboardInput(true)
  end
end

--- Syncs gutter scroll via the real API, not a manual re-anchor.
--- @param offset number
function o:OnCodeEditBoxScroll(offset) self.Gutter:SetVerticalScroll(offset) end

function o:OnCodeEditBoxTextChanged()
  -- Can fire during construction, before self.CodeEditBox is aliased.
  if not self.CodeEditBox then return end

  -- Skip while hidden; OnLoad's RefreshGutter already did the initial sync.
  if not self:IsShown() then return end

  -- WoW re-fires OnTextChanged even when the contents did not actually change,
  -- and RefreshGutter resizes the box, which provokes yet more events -- that
  -- cycle ran every frame and kept the caret from ever rendering. Only do the
  -- work when the text really differs.
  local text = self.CodeEditBox:GetText()
  if text == self.lastGutterText then return end
  self.lastGutterText = text

  self:RefreshGutter()
  self:RefreshDirtyMark()
end

--- Keeps the caret's line visible by scrolling ScrollFrame just enough to
--- bring it back into view (snap-to-edge, not centered) -- e.g. pressing Up at
--- the top row previously left the caret scrolled off-screen with no visual
--- feedback. Horizontal position is handled natively by the EditBox/ScrollFrame
--- pairing, so only vertical is done here.
--- y/h come from the EditBox's own OnCursorChanged(x, y, w, h): y is the
--- caret's top offset from the EditBox's top edge, reported negative-down
--- (confirmed against Blizzard's own ScrollingEdit_OnCursorChanged, which
--- negates it the same way), so -y is the caret's actual downward offset.
--- Gated by SizeDiffers like every other write in this file: an unguarded
--- SetVerticalScroll here previously self-triggered forever, because the old
--- resize churn re-fired this same event mid-scroll -- see CodeEditBoxMixin.lua.
--- That churn is gone now (RefreshGutter's SizeDiffers guards), which is what
--- makes this safe to add.
--- @param x number
--- @param y number
--- @param w number
--- @param h number
function o:OnCodeEditBoxCursorChanged(x, y, w, h)
  local scrollFrame = self.ScrollFrame
  local viewHeight = scrollFrame:GetHeight()
  local scroll = scrollFrame:GetVerticalScroll()
  local cursorTop = -y
  local cursorBottom = cursorTop + h

  local target
  if cursorTop < scroll then
    target = cursorTop
  elseif cursorBottom > scroll + viewHeight then
    target = cursorBottom - viewHeight
  end

  if target and SizeDiffers(scroll, target) then scrollFrame:SetVerticalScroll(target) end

  -- Anchor moves unless Shift+click; typing '(' also holds Shift.
  local editBox = self.CodeEditBox
  local current = editBox:GetCursorPosition()
  local shiftClick = IsShiftKeyDown() and IsMouseButtonDown('LeftButton')
  if shiftClick and self.cursorAnchor then
    if current > self.cursorAnchor then
      editBox:HighlightText(self.cursorAnchor, current)
    else
      editBox:HighlightText(current, self.cursorAnchor)
    end
  else
    self.cursorAnchor = current
  end
end

--- PAGEUP/PAGEDOWN: moves the caret one viewport (two with Cmd) up/down.
--- @param key "PAGEUP"|"PAGEDOWN"
function o:OnCodeEditBoxPageKey(key)
  local lines = ViewportLines(self)
  if IsMetaKeyDown() then lines = lines * 2 end
  PageMoveCursor(self, key == 'PAGEUP' and -1 or 1, lines)
end

--- Cmd/Ctrl+1: runs the buffer. Not Enter, which types a newline
--- over any selection with no way to block it.
function o:OnCodeEditBoxRunKey() self:Run() end

--- Cmd+Home/End: jumps the caret to document start/end.
--- @param key "HOME"|"END"
function o:OnCodeEditBoxDocumentJumpKey(key)
  local editBox = self.CodeEditBox
  if key == 'HOME' then
    editBox:SetCursorPosition(0)
    return
  end
  -- FAIAP.coloredGetText, not editBox:GetText(): once colorization is
  -- enabled, GetText is overridden to always return decoded (color-code-
  -- stripped) text -- shorter than what SetCursorPosition/GetCursorPosition
  -- actually operate against (the raw text, full of |cRRGGBBAA...|r codes).
  -- Using the decoded length as a raw cursor offset landed well short of
  -- the true end. coloredGetText calls the original, un-overridden GetText
  -- FAIAP captured before replacing it, so this gets the real raw text
  -- regardless of whether colorization is active.
  local rawText = FAIAP.coloredGetText(editBox)
  editBox:SetCursorPosition(#rawText)
end

--- ScrollFrame resized (e.g. SizerSE drag); re-wrap against the new width.
function o:OnCodeViewportSizeChanged()
  if not self.CodeEditBox then return end
  self:RefreshGutter()
end

--- User-driven change (checkbox click); saved.
--- @param checked boolean
function o:OnWrapToggled(checked) self:SetWrapText(checked, true) end

--- @param name Name?    @Unknown names fall back to the default theme
--- @param save boolean? @Save to the DB (user-driven change); omit for internal/initial sets
function o:ApplyTheme(name, save)
  local bs = bdrops:GetBorderSettings(name)
  if not bs then return end

  local main = bs.main
  self.borderStyle = bs.name
  local bd = main.backdrop
  if bd then
    self:SetBackdrop(Omit(bd, 'edgeFile'))
    self.Border:SetBackdrop(Omit(bd, 'bgFile'))
    if bd.borderColor then self.Border:SetBackdropBorderColor(unpack(bd.borderColor)) end
    if bd.bgColor then self:SetBackdropColor(unpack(bd.bgColor)) end
    self:InsetPanels(bd.insets)
  end

  local gutterTextColor = GUTTER.textColor
  local pbd = bs.panel.backdrop
  local bgColor, borderColor = pbd.bgColor, pbd.borderColor

  self.GutterBackdrop:SetBackdrop(pbd)
  self.CodeBackdrop:SetBackdrop(pbd)
  self.StatusBar:SetBackdrop(pbd)
  self.CommandBar:SetBackdrop(pbd)

  if bgColor then
    self.CodeBackdrop:SetBackdropColor(upk(bgColor))
    self.StatusBar:SetBackdropColor(upk(bgColor))
    self.CommandBar:SetBackdropColor(upk(bgColor))
  end
  if borderColor then
    self.CodeBackdrop:SetBackdropBorderColor(upk(borderColor))
    self.StatusBar:SetBackdropBorderColor(upk(borderColor))
    self.CommandBar:SetBackdropBorderColor(upk(borderColor))
  end
  local gutter = bs.code and bs.code.gutter
  if gutter and gutter.textColor then gutterTextColor = gutter.textColor end
  -- Grip color is tuned per theme; panel.backdrop.borderColor alpha is too low here.
  local console = bs.console
  local divider = console.divider
  -- Both remembered so OnStatusDividerHover can swap between them.
  self.statusGripColor = divider.gripColor
  self.statusGripHoverColor = divider.gripHoverColor
  self.StatusDivider.Grip:SetColorTexture(upk(divider.gripColor))
  self.StatusDivider.MaximizeButton.NormalTexture:SetVertexColor(upk(divider.arrowColor))
  self.StatusDivider.MinimizeButton.NormalTexture:SetVertexColor(upk(divider.arrowColor))
  local output, commandLine = console.output, console.commandLine or {}
  local commandColor = commandLine.textColor or output.textColor
  local prompt = commandLine.prompt or {}
  self.EvalStatus:SetTextColor(upk(output.textColor))
  self.CommandBar.Prompt:SetTextColor(upk(prompt.color or commandColor))
  self.CommandEditBox:SetTextColor(upk(commandColor))
  self:ApplyConsoleInsets(console)
  self:ApplyToolIconAlpha(output)
  -- gutter borderColor is alpha 0 (hidden)
  self.GutterBackdrop:SetBackdropBorderColor(upk(GUTTER.borderColor))
  self.GutterBackdrop:SetBackdropColor(upk(GUTTER.bgColor))
  self.Gutter.ScrollChild.Numbers:SetTextColor(upk(gutterTextColor))
  self:_SetHeaderBorderStyle(bs)
  if save then ns:editor().theme = self.borderStyle end
end

--- NormalTexture only: the hover highlight stays full strength.
--- @param output LDK_OutputTheme
function o:ApplyToolIconAlpha(output)
  local alpha = (output.toolIcons or {}).alpha or TOOL_ICON_ALPHA
  self.ConsoleSettingsButton:GetNormalTexture():SetAlpha(alpha)
  self.ClearOutputButton:GetNormalTexture():SetAlpha(alpha)
end

--- Places the gear, history arrow and prompt per border.
--- @param console LDK_ConsoleTheme
function o:ApplyConsoleInsets(console)
  local toolIcons = console.output.toolIcons or {}
  local gear = toolIcons.inset or TOOL_ICON_INSET
  local settings = self.ConsoleSettingsButton
  settings:ClearAllPoints()
  settings:SetPoint('TOPRIGHT', self.StatusBar, 'TOPRIGHT', -gear.x, -gear.y)

  -- Not self.HistoryButton: OnLoad themes before aliasing it.
  local bar = self.CommandBar
  local history, nudge = bar.HistoryButton, 4.7
  local x = -gear.x + nudge
  history:ClearAllPoints()
  history:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', x, 0)
  history:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', x, 0)

  local commandLine = console.commandLine or {}
  local promptTheme = commandLine.prompt or {}
  local offset = promptTheme.offset or PROMPT_OFFSET
  local prompt = bar.Prompt
  prompt:ClearAllPoints()
  prompt:SetPoint('LEFT', bar, 'LEFT', offset.x, offset.y)
end

--- @private
--- @param bs LDK_ThemeSet
function o:_SetHeaderBorderStyle(bs)
  local bd = bs.main.backdrop
  local height = HEADER_HEIGHT
  local bgColor = bd.bgColor or { 0.73, 0.73, 0.73, 1.0 }
  local borderColor = bd.borderColor or { 0.56, 0.56, 0.56, 1.0 }

  local hbo = bdrops:GetHeaderBackdropOverride(bs)
  if hbo then
    local hbd = hbo.backdrop
    if hbd then
      bd = hbd
      if hbd.bgColor then bgColor = hbd.bgColor end
      if hbd.borderColor then borderColor = hbd.borderColor end
    end
    if bs.main.header.height then height = bs.main.header.height end
  end
  self.Header:SetBackdrop(bd)
  self.Header:SetBackdropColor(unpack(bgColor))
  self.Header:SetBackdropBorderColor(unpack(borderColor))
  self.Header:SetHeight(height)
end

--- Applies a font to the code box, gutter numbers, and wrap measuring string.
--- @param fontFamily string Key into FontUtil:GetFontChoices()
--- @param save boolean? @Save to the DB (user-driven change); omit for internal/initial sets
function o:SetCodeFont(fontFamily, save)
  local choice = fut:FindFontChoice(fontFamily)
  if not choice then return end
  self.fontFamily = choice.key
  self:ApplyCodeFont(save)
end

--- Re-resolves and applies the font for the current fontFamily/fontSize.
--- @param save boolean? @Save to the DB (user-driven change); omit for internal/initial sets
function o:ApplyCodeFont(save)
  local choice = fut:FindFontChoice(self.fontFamily)
  if not choice then return end
  local font = choice.bySize[self.fontSize]
  self.codeFont = font

  -- EditBox has its own SetFontObject/SetFont/GetFont, no GetFontString().
  self.CodeEditBox:SetFontObject(font)
  self.Gutter.ScrollChild.Numbers:SetFontObject(font)
  self.WrapMeasure.Text:SetFontObject(font)
  self:ApplyConsoleFont()

  -- Gray out the steppers at the size list ends.
  local sizes = fut:GetFontSizes()
  local canShrink, canGrow = self.fontSize ~= sizes[1], self.fontSize ~= sizes[#sizes]
  C_Timer.After(0.1, function()
    self.FontSteppers.MinusButton:SetEnabled(canShrink)
    self.FontSteppers.PlusButton:SetEnabled(canGrow)
  end)

  -- RefreshGutter re-sizes the gutter for the new font's digit width.
  self:RefreshGutter()
  if not save then return end
  local editor = ns:editor()
  editor.fontFamily, editor.fontSize = self.fontFamily, self.fontSize
end

--- User-driven pick from the console settings menu; saved.
--- @param fontFamily string? @nil follows the editor's font
--- @param fontSize number?   @nil follows the editor's size
function o:SetConsoleFont(fontFamily, fontSize)
  self.consoleFontFamily = fontFamily
  self.consoleFontSize = fontSize
  self:ApplyConsoleFont()
  local console = ns:g().console
  console.fontFamily = fontFamily or DB.SAME_AS_EDITOR_FONT
  console.fontSize = fontSize or DB.SAME_AS_EDITOR_SIZE
end

--- Output and command line font; nil console picks follow the editor.
function o:ApplyConsoleFont()
  local choice = fut:FindFontChoice(self.consoleFontFamily or self.fontFamily)
  if not choice then return end
  local size = self.consoleFontSize or self.fontSize
  local font = choice.bySize[size]

  -- Must set justify here: SetFontObject resets it.
  self.EvalStatus:SetFontObject(font)
  self.EvalStatus:SetJustifyH('LEFT')

  self.CommandEditBox:SetFontObject(font)
end

--- Sets the font size (snapped to the nearest supported size) and re-applies
--- the current font family at that size.
--- @param fontSize number
--- @param save boolean? @Save to the DB (user-driven change); omit for internal/initial sets
function o:SetFontSize(fontSize, save)
  self.fontSize = fut:NearestFontSize(fontSize)
  self:ApplyCodeFont(save)
end

--- Steps the font size, clamped at the ends. Always user-driven; saved.
--- @param delta 1|-1
function o:StepFontSize(delta)
  local sizes = fut:GetFontSizes()
  local index = 1
  for i, size in ipairs(sizes) do
    if size == self.fontSize then
      index = i
      break
    end
  end
  local newIndex = Clamp(index + delta, 1, #sizes)
  if newIndex == index then return end
  self:SetFontSize(sizes[newIndex], true)
end

--- Toggles wrap mode: oversized EditBox vs. pinned to viewport width.
--- @param enabled boolean
--- @param save boolean? @Save to the DB (user-driven change); omit for internal/initial sets
function o:SetWrapText(enabled, save)
  self.wrapText = enabled and true or false
  self.BottomBar.WrapCheckButton:SetChecked(self.wrapText)
  local editBox = self.CodeEditBox
  if self.wrapText then
    editBox:SetWidth(self.ScrollFrame:GetWidth())
    self.ScrollFrame:SetHorizontalScroll(0)
  else
    editBox:SetWidth(4000)
  end
  self:RefreshGutter()
  if save then ns:editor().wrapText = self.wrapText end
end

--- Applies the saved settings; doesn't write back.
--- @see LDK_CodeEditorDialogMixin.Initialize
function o:Configure()
  local g = ns:g()
  local editor = g.editor
  -- Console first: ConfigureEditor applies its font too.
  self:ConfigureConsoleFont(g.console)
  self:ConfigureEditor(editor)
  local wrapText = editor.wrapText
  if wrapText == nil then wrapText = DEFAULTS.wrapText end
  self:SetWrapText(wrapText)
  self:ConfigureOutputHeight()
end

--- Unclamped: OnShow clamps it once the dialog has a layout.
function o:ConfigureOutputHeight() self.StatusBar:SetHeight(ns:p().outputHeight) end

--- Applies the saved theme, code font and size.
--- @param editor LDK_DB_EditorConfig
function o:ConfigureEditor(editor)
  self:ApplyTheme(editor.theme)
  self.fontSize = fut:NearestFontSize(editor.fontSize)
  self:SetCodeFont(ResolveFontFamily(editor.fontFamily))
end

--- SAME_AS_EDITOR values or an unresolvable font follow the editor.
--- @param console LDK_DB_ConsoleConfig
function o:ConfigureConsoleFont(console)
  local fontFamily = console.fontFamily
  local followFont = fontFamily == DB.SAME_AS_EDITOR_FONT or not fut:FindFontChoice(fontFamily)
  self.consoleFontFamily = not followFont and fontFamily or nil
  local fontSize = console.fontSize
  local followSize = fontSize == DB.SAME_AS_EDITOR_SIZE
  self.consoleFontSize = not followSize and fut:NearestFontSize(fontSize) or nil
end

--- Rebuilds the gutter's "1..N" text and sizes both columns to the content.
function o:RefreshGutter()
  if not self.CodeEditBox then return end -- not constructed yet (see OnCodeEditBoxTextChanged)

  -- Reentrancy guard: SetText fires OnTextChanged inline, landing back here.
  if self.refreshingGutter then return end
  self.refreshingGutter = true

  local gutter = self.Gutter
  local child = gutter.ScrollChild
  local numbers = child.Numbers

  -- Every setter below is guarded by SizeDiffers. Re-applying an unchanged size
  -- still makes WoW re-fire OnSizeChanged and recompute the caret (firing
  -- OnCursorChanged), so an unguarded SetHeight here re-entered this function
  -- every frame forever -- the size never changed, but the events never stopped,
  -- and the constant caret recalculation kept the cursor from ever rendering.

  -- Must size first: the code viewport anchors off GutterBackdrop's edge.
  local lastLine = CountLines(self)
  local backdropWidth = GutterWidth(self, lastLine)
  if SizeDiffers(self.GutterBackdrop:GetWidth(), backdropWidth) then
    self.GutterBackdrop:SetWidth(backdropWidth)
  end

  -- Scroll children ignore right-side anchors; width must be set explicitly.
  local gutterWidth = gutter:GetWidth()
  if SizeDiffers(child:GetWidth(), gutterWidth) then child:SetWidth(gutterWidth) end

  if self.wrapText then
    -- Keep EditBox and measuring string wrapping at the same width.
    local textWidth = CodeTextWidth(self)
    local viewportWidth = self.ScrollFrame:GetWidth()
    if SizeDiffers(self.CodeEditBox:GetWidth(), viewportWidth) then
      self.CodeEditBox:SetWidth(viewportWidth)
    end
    if SizeDiffers(self.WrapMeasure.Text:GetWidth(), textWidth) then
      self.WrapMeasure.Text:SetWidth(textWidth)
    end
  end

  local text, rows
  local digits = GutterDigits(lastLine)
  if self.wrapText then
    text, rows = WrappedLineNumbersText(self, digits)
  else
    text, rows = LineNumbersText(lastLine, digits)
  end

  -- Both columns render the same row count in the same font, so rows times the
  -- Sizes both columns identically so their scroll ranges stay in sync.
  local lineHeight = self.WrapMeasure.Text:GetLineHeight()
  local contentHeight = math.max(rows * lineHeight, self.ScrollFrame:GetHeight())
  if SizeDiffers(child:GetHeight(), contentHeight) then child:SetHeight(contentHeight) end
  if SizeDiffers(self.CodeEditBox:GetHeight(), contentHeight) then
    self.CodeEditBox:SetHeight(contentHeight)
  end

  -- Text goes in only after both columns are at their final height: the
  -- numbers EditBox lays its text out against the height it has at SetText
  -- time, and a layout committed against the old, shorter height stayed
  -- truncated (trailing "...") even after the child grew underneath it.
  -- The EditBox truncates at its 'letters' cap, ending the gutter mid-number
  -- and dropping every line below it -- the cutoff tracks the character count,
  -- not the column width. Raised to fit this text before every SetText, since
  -- the count grows with the file: any fixed cap is just a later ceiling.
  -- strlenutf8, not #text: SetMaxLetters counts characters while # counts
  -- bytes, so a byte count overshoots wherever the text is multi-byte. Same
  -- value for ASCII digits, correct everywhere else.
  numbers:SetMaxLetters(strlenutf8(text))
  numbers:SetText(text)
  -- Reset caret; else the gutter scrolls toward it, out of line with code.
  numbers:SetCursorPosition(0)

  self.refreshingGutter = false
end

--[[-----------------------------------------------------------------------------
Status bar: divider drag and evaluation output
-------------------------------------------------------------------------------]]
--- Sets the output panel's height, clamped so neither panel can be squeezed
--- away. The code area needs no work of its own: GutterBackdrop and
--- CodeBackdrop anchor their bottoms to StatusDivider, so it follows.
--- @param height number
--- @param save boolean? @Save to the DB (user-driven change); omit for re-clamps
function o:SetStatusHeight(height, save)
  local maxHeight = MaxStatusHeight(self)
  height = Clamp(height, MIN_STATUS_HEIGHT, maxHeight)
  if SizeDiffers(self.StatusBar:GetHeight(), height) then self.StatusBar:SetHeight(height) end
  if save then ns:p().outputHeight = height end
  -- Disable the arrow for whichever end the panel is already at.
  local divider = self.StatusDivider
  UpdateArrowState(divider.MaximizeButton, SizeDiffers(height, maxHeight))
  UpdateArrowState(divider.MinimizeButton, SizeDiffers(height, MIN_STATUS_HEIGHT))
end

--- @return number
function o:GetStatusHeight() return self.StatusBar:GetHeight() end

--- Grows the output panel as far as MIN_CODE_HEIGHT allows (the up arrow).
function o:MaximizeStatus() self:SetStatusHeight(MaxStatusHeight(self), true) end

--- Shrinks the output panel to MIN_STATUS_HEIGHT (the down arrow).
function o:MinimizeStatus() self:SetStatusHeight(MIN_STATUS_HEIGHT, true) end

--- @return boolean
function o:IsStatusMax() return not SizeDiffers(self:GetStatusHeight(), MaxStatusHeight(self)) end

--- @return string @Locale key for what a double-click does next
function o:DividerHintKey()
  return self:IsStatusMax() and 'Double-click to minimize' or 'Double-click to maximize'
end

--- Double-clicking the divider: maximizes, or minimizes if already max.
function o:ToggleStatus()
  if self:IsStatusMax() then
    self:MinimizeStatus()
  else
    self:MaximizeStatus()
  end
end

--- Tracked by hand; StartSizing only resizes the dialog, not a child.
function o:OnStatusDividerMouseDown()
  local divider = self.StatusDivider
  divider.cursorStart = select(2, GetCursorPosition())
  divider.heightStart = self.StatusBar:GetHeight()
  divider:SetScript('OnUpdate', function() self:OnStatusDividerUpdate() end)
end

function o:OnStatusDividerMouseUp() self.StatusDivider:SetScript('OnUpdate', nil) end

--- Drag moves StatusBar's top edge; divides by scale (pixels vs UI units).
function o:OnStatusDividerUpdate()
  local divider = self.StatusDivider
  if not divider.cursorStart then return end
  local delta = (select(2, GetCursorPosition()) - divider.cursorStart) / self:GetEffectiveScale()
  self:SetStatusHeight(divider.heightStart + delta, true)
end

--- @param hovered boolean
function o:OnStatusDividerHover(hovered)
  local color = hovered and self.statusGripHoverColor or self.statusGripColor
  self.StatusDivider.Grip:SetColorTexture(upk(color))
end

--- Drops every line of output collected so far.
function o:ClearOutput()
  self.output:Clear()
  self:RefreshOutput()
end

--- Rewrites the output box from the output log.
function o:RefreshOutput()
  local box = self.EvalStatus
  local child = self.OutputScrollFrame.ScrollChild
  -- Scroll children ignore right anchors; set width here.
  local width = self.OutputScrollFrame:GetWidth()
  -- Zero until the first layout pass; OnSizeChanged retries.
  if width > 0 and SizeDiffers(child:GetWidth(), width) then child:SetWidth(width) end
  self:SyncOutputHeight()

  -- A divider drag re-enters this every frame.
  local text = self.output:GetText()
  if box:GetText() == text then return end
  -- Raised before every SetText; see RefreshGutter for why.
  box:SetMaxLetters(strlenutf8(text))
  box:SetText(text)
end

--- Floors the child at viewport height so short output stays bottom-aligned.
function o:SyncOutputHeight()
  local child = self.OutputScrollFrame.ScrollChild
  local height = math.max(self.EvalStatus:GetHeight(), self.OutputScrollFrame:GetHeight())
  if SizeDiffers(child:GetHeight(), height) then child:SetHeight(height) end
end

--- Appends output; embedded newlines count toward the cap.
--- @param text string
function o:AppendOutput(text)
  self.output:Append(text)
  self:RefreshOutput()
end

--- @return string
function o:GetOutput() return self.output:GetText() end

--[[-----------------------------------------------------------------------------
Command line: single-shot eval; no multi-line continuation
-------------------------------------------------------------------------------]]
--- Runs one line from the command bar and appends every outcome -- the echoed
--- input, a compile error, a runtime error, or printed output -- to the same
--- output panel a full Run uses.
--- @param text string
function o:OnCommandEnterPressed(text)
  if str_isBlank(text) then return end

  -- Escape literal '|' so the echoed input can't be read as a color/texture code.
  self:AppendOutput(COMMAND_ECHO_PREFIX .. text:gsub('|', '||'))

  local ok = LR:EvalCommand(text, function(line) self:AppendOutput(line) end)
  self:PushCommandHistory(text, not ok)
end

--[[-----------------------------------------------------------------------------
Documents: New and the Open stepper, backed by DocumentStore
-------------------------------------------------------------------------------]]
--- Starts an empty document and switches to it.
function o:NewDocument()
  self:ConfirmLeaveDocument(function() self:AddDocument('') end)
end

--- Shows the profile's first document; starts one if it has none.
function o:LoadDocuments()
  if DS:Count() == 0 then return self:AddDocument(STARTER_CODE) end
  self:OpenDocument(1)
end

--- @param text string
function o:AddDocument(text)
  local name = L['Untitled'] .. ' ' .. (DS:Count() + 1)
  self:OpenDocument(DS:Add(name, text))
end

--- Programmatic switch: the menu won't refresh on its own.
--- @param index number
function o:OpenDocument(index)
  self:ShowDocument(index)
  self.DocStepper.Dropdown:GenerateMenu()
end

--- Loads the document at index; unsaved edits are dropped.
--- @see LDK_CodeEditorDialogMixin.ConfirmLeaveDocument
--- @param index number
function o:ShowDocument(index)
  if index == self.docIndex then return end
  self.docIndex = index
  self:SetText(DS:Get(index).text)
  self.CodeEditBox:SetCursorPosition(0)
  -- OnTextChanged skips text equal to the last document's.
  self:RefreshDirtyMark()
end

--- Copies the editor text into the current document.
function o:SaveDocument()
  if self.docIndex then DS:SetText(self.docIndex, self:GetText()) end
  self:RefreshDirtyMark()
end

--- Regenerates the document menu only when the dirty state flips.
function o:RefreshDirtyMark()
  local dirty = self:IsDirty()
  if dirty == self.dirtyShown then return end
  self.dirtyShown = dirty
  self.DocStepper.Dropdown:GenerateMenu()
end

--- @return boolean @true if the editor text differs from the saved document
function o:IsDirty()
  local doc = self.docIndex and DS:Get(self.docIndex)
  return doc ~= nil and self:GetText() ~= doc.text
end

--- Runs proceed now if the document is clean, else after the prompt.
--- @param proceed fun()
function o:ConfirmLeaveDocument(proceed)
  if not self:IsDirty() then return proceed() end
  StaticPopup_Show(UNSAVED_PROMPT, self:DocumentName(), nil, proceed)
end

--- @param heading string
--- @param name string                @Prefilled and selected
--- @param onAccept fun(name: string) @Gets the trimmed, non-empty name
local function PromptDocumentName(heading, name, onAccept)
  --- @class LDK_DocNamePromptData
  local data = { name = name, onAccept = onAccept }
  StaticPopup_Show(NAME_PROMPT, heading, nil, data)
end

function o:PromptRenameDocument()
  local index = self.docIndex
  if not index then return end
  PromptDocumentName(
    L['Rename Document'],
    self:DocumentName(),
    function(name) self:RenameDocument(index, name) end
  )
end

--- @param index number
--- @param name string
function o:RenameDocument(index, name)
  DS:SetName(index, name)
  self.DocStepper.Dropdown:GenerateMenu()
end

--- Unsaved edits go to the copy; the original keeps its saved text.
function o:PromptSaveDocumentAs()
  PromptDocumentName(
    L['Save Document As'],
    L['%s Copy']:format(self:DocumentName()),
    function(name) self:SaveDocumentAs(name) end
  )
end

--- @param name string
function o:SaveDocumentAs(name) self:OpenDocument(DS:Add(name, self:GetText())) end

function o:PromptDeleteDocument()
  if not self.docIndex then return end
  StaticPopup_Show(DELETE_PROMPT, self:DocumentName(), nil, self.docIndex)
end

--- Deleting the current document shows its neighbor; the
--- last one left is replaced by an empty document.
--- @param index number
function o:DeleteDocument(index)
  -- Their callbacks hold indexes that are about to shift.
  StaticPopup_Hide(UNSAVED_PROMPT)
  StaticPopup_Hide(NAME_PROMPT)
  DS:Remove(index)
  local current = self.docIndex
  if index ~= current then
    if current and index < current then self.docIndex = current - 1 end
    return self.DocStepper.Dropdown:GenerateMenu()
  end
  self.docIndex = nil
  if DS:Count() == 0 then return self:AddDocument('') end
  self:OpenDocument(math.min(index, DS:Count()))
end

--- One radio per document; the steppers walk the same radios.
--- @param root RootMenuDescriptionProxy
function o:BuildDocumentMenu(root)
  local function isSelected(index) return index == self.docIndex end
  local function pick(index)
    if index == self.docIndex then return end
    self:ConfirmLeaveDocument(function()
      self:ShowDocument(index)
      -- Stepper picks have no open menu to refresh the arrows.
      self.DocStepper.Dropdown:SignalUpdate()
    end)
  end
  local function label(index, doc)
    local dirty = index == self.docIndex and self.dirtyShown
    return dirty and DIRTY_MARK .. doc.name or doc.name
  end
  DS:Each(function(index, doc) root:CreateRadio(label(index, doc), isSelected, pick, index) end)
  root:SetScrollMode(DOC_MENU_MAX_HEIGHT)
end

--[[-----------------------------------------------------------------------------
Run: evaluates the whole editor buffer
-------------------------------------------------------------------------------]]
function o:ToggleSaveOnRun()
  local editor = ns:editor()
  editor.saveOnRun = not editor.saveOnRun
end

--- Saves the document first if Save on Run is on; output goes to the output panel.
function o:Run()
  if ns:editor().saveOnRun then self:SaveDocument() end
  local text = self:GetText()
  if str_isBlank(text) then return end
  self:AppendOutput(COMMAND_ECHO_PREFIX .. 'run ' .. self:DocumentName())
  LR:EvalCode(text, function(line) self:AppendOutput(line) end)
end

--- @return string
function o:DocumentName()
  local doc = self.docIndex and DS:Get(self.docIndex)
  return doc and doc.name or L['Untitled']
end

--- @return string
function o:GetText() return self.CodeEditBox:GetText() end

--- Text past MAX_LINES is dropped; unbounded truncated the gutter before.
--- @param text string
function o:SetText(text)
  self.CodeEditBox:SetText(TrimToMaxLines(text or ''))
  self:RefreshGutter()
end
