--[[-----------------------------------------------------------------------------
CodeEditorDialog: standalone (non-Ace3) line-numbered code editor prototype.
Self-contained: not wired into the DevSuite namespace/module registry.
See GitHub issue #90.
-------------------------------------------------------------------------------]]
--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local cns, O = ns:cns(), ns:cns().O
local bdrops, String = O.Backdrops, O.String
local fut, FAIAP, lsm = O.FontUtil, O.FAIAP, O.LSM
local mt = lsm.MediaType
local str_eq, str_isBlank = String.EqualsIgnoreCase, String.IsBlank
local upk = unpack
local L = cns:GetLocale()

local libName = 'CodeEditorDialog'

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local CreateFrame = CreateFrame
local strlenutf8 = strlenutf8

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
local GUTTER = {
  useCodeBorderColor = false,
  borderColor = { 0.133, 0.341, 0.031, 0 },
  bgColor = { 0, 0, 0, 0 },
  textColor = { 1, 1, 1, 1.0 },
}

local HEADER_HEIGHT = 28

-- StatusBar's initial height; clamped via MIN_CODE_HEIGHT.
local STATUS_BAR_HEIGHT = 100
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

-- OptionsButton arrow glyph; sized by the atlas, not the button.
local OPTIONS_ARROW_SIZE = 18

-- Horizontal text padding inside CodeEditBox (left, right).
local CODE_TEXT_INSET_LEFT = 0
local CODE_TEXT_INSET_RIGHT = 6

-- Shared inset so the code area's corner buttons line up.
local OVERLAY_INSET = 4

-- Breathing room on whichever axis shrinks when clamped to screen.
local SCREEN_MARGIN = 100

local fontChoices, defaultFontChoice = fut:GetFontChoices(), fut:GetDefaultFontChoice()

-- Configure() defaults; shape of the OnConfigChanged snapshot.
local DEFAULTS = {
  -- Literal key; cns:GetFonts() here fails SetFont too early.
  fontFamily = defaultFontChoice and defaultFontChoice.key,
  fontSize = 14,
  wrapText = false,
}

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_CodeEditorGutterChild : Frame
--- @field Numbers EditBox Read-only "1\n2\n...\nN" in the code font, padded to a common digit width

--- @class LDK_CodeEditorGutter : ScrollFrame
--- @field ScrollChild LDK_CodeEditorGutterChild

--- @class LDK_CodeEditorBottomBar : Frame
--- @field WrapCheckButton CheckButton

--- @class LDK_CodeEditorCommandBar : Frame, BackdropTemplate
--- @field Prompt FontString Static "> " glyph, left of the input
--- @field CommandEditBox EditBox Single-line quick-eval input, historyLines=100

--- @class LDK_CodeEditorOutputScrollChild : Frame
--- @field EvalStatus EditBox Read-only output log; an EditBox so text can be selected and copied

--- @class LDK_CodeEditorOutputScrollFrame : ScrollFrame
--- @field ScrollChild LDK_CodeEditorOutputScrollChild Floored at viewport height to keep output bottom-aligned

--- @class LDK_CodeEditorStatusBar : Frame, BackdropTemplate
--- @field OutputScrollFrame LDK_CodeEditorOutputScrollFrame Clips the output box; wheel-scrolled, no scrollbar

--- @class LDK_CodeEditorStatusDivider : Button
--- @field Grip Texture The draggable handle, colored by ApplyTheme
--- @field MaximizeButton Button Up arrow above the divider's right end; grows StatusBar to its max
--- @field MinimizeButton Button Down arrow right of MaximizeButton; shrinks StatusBar to its min
--- @field cursorStart number|nil Screen Y at drag start
--- @field heightStart number|nil StatusBar height at drag start

--- @class LDK_CodeEditorHeaderTitle : Frame
--- @field Text FontString The dialog title, centered

--- @class LDK_CodeEditorHeaderCloseFrame : Frame
--- @field CloseButton Button

--- @class LDK_CodeEditorHeader : Frame, BackdropTemplate
--- @field Title LDK_CodeEditorHeaderTitle Fluid: absorbs all width left by CloseFrame
--- @field CloseFrame LDK_CodeEditorHeaderCloseFrame Fixed 32px, pinned right

--- @class LDK_CodeEditorFontSteppers : Frame
--- @field MinusButton Button Steps the font size down
--- @field PlusButton Button Steps the font size up

--- @class LDK_CodeEditorWrapMeasure : Frame
--- @field Text FontString Hidden; same font/wrap as CodeEditBox, used to count wrapped rows

--- @class LDK_CodeEditorOptions
--- @field fontFamily string Key into FontUtil:GetFontChoices(), e.g. 'UbuntuMono'
--- @field fontSize number One of FontUtil:GetFontSizes() (10/12/14/16/18/20/24/28); other values snap to nearest
--- @field wrapText boolean

--- @class LDK_CodeEditorDialogMixin : Frame, BackdropTemplate
--- @field Header LDK_CodeEditorHeader Full-width title bar; carries drag-to-move
--- @field TopBar Frame Reserved space for future toolbar/controls
--- @field FontDropdown Frame The font-choice UIDropDownMenu, anchored inside TopBar
--- @field FontSizeDropdown Frame The font-size UIDropDownMenu, anchored inside TopBar
--- @field codeFont Font Currently applied font object
--- @field fontFamily string Key of the currently applied font (see FontUtil:GetFontChoices())
--- @field fontSize number Current fontSize option, applied to rendering (snapped to FontUtil:GetFontSizes())
--- @field BottomBar LDK_CodeEditorBottomBar
--- @field CommandBar LDK_CodeEditorCommandBar Single-line eval prompt between StatusBar and BottomBar
--- @field CommandEditBox EditBox Alias of CommandBar.CommandEditBox
--- @field StatusBar LDK_CodeEditorStatusBar Output panel between the code area and BottomBar
--- @field StatusDivider LDK_CodeEditorStatusDivider Drag handle that sets StatusBar's height
--- @field OutputScrollFrame LDK_CodeEditorOutputScrollFrame Alias of StatusBar.OutputScrollFrame
--- @field EvalStatus EditBox Alias of StatusBar.OutputScrollFrame.ScrollChild.EvalStatus
--- @field outputLines string[] Appended evaluation output, capped at MAX_OUTPUT_LINES
--- @field WrapMeasure LDK_CodeEditorWrapMeasure
--- @field wrapText boolean Current wrap-mode state
--- @field onConfigChanged fun(self: LDK_CodeEditorDialog, options: LDK_CodeEditorOptions)|nil
--- @field GutterBackdrop Frame|BackdropTemplate Draws the gutter's border; Gutter is inset inside it
--- @field Gutter LDK_CodeEditorGutter
--- @field CodeBackdrop Frame|BackdropTemplate Draws the code area's border; ScrollFrame is inset inside it
--- @field ScrollFrame ScrollFrame
--- @field CodeEditBox LDK_CodeEditBox
--- @field CloseButton Button
--- @field SizerSE Frame Bottom-right resize grip
--- @field FontSteppers LDK_CodeEditorFontSteppers Floating +/- over the code area's top right
--- @field Border Frame|BackdropTemplate Main edge art; draws over StatusBar and CommandBar
--- @field HeaderTitle FontString
--- @field borderStyle Name
--- @field statusGripColor RGBA Resting divider grip color, from the active theme
--- @field statusGripHoverColor RGBA Hovered divider grip color, from the active theme
LDK_CodeEditorDialogMixin = {}
local o = LDK_CodeEditorDialogMixin

--
--- @class LDK_CodeEditorDialog : LDK_CodeEditorDialogMixin
--

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Copy of a backdrop without one of its pieces.
--- @param bd LDK_Backdrop
--- @param key string 'bgFile' or 'edgeFile'
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
  -- Trailing '\n' keeps a final empty line, matching CountLines().
  for line in (text .. '\n'):gmatch('(.-)\n') do
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
  -- Trailing '\n' keeps a final empty line counted, matching CountLines().
  for line in (self.CodeEditBox:GetText() .. '\n'):gmatch('(.-)\n') do
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
--- @return number
local function MaxStatusHeight(self)
  local top, bottom = self.TopBar:GetBottom(), self.BottomBar:GetTop()
  if not top or not bottom then return STATUS_BAR_HEIGHT end
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
  return function() if GameTooltip:IsOwned(frame) then show() end end
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
  -- Alias onto this dialog frame; hoisted for OnLoad_Viewports.
  self.CodeEditBox = self.ScrollFrame.CodeEditBox
  self.OutputScrollFrame = self.StatusBar.OutputScrollFrame
  self.EvalStatus = self.OutputScrollFrame.ScrollChild.EvalStatus
  self.CommandEditBox = self.CommandBar.CommandEditBox

  self:OnLoad_Viewports()
  self:OnLoad_Overlays()
  self:OnLoad_GripLines()
  self:OnLoad_EditBoxScrollBar()

  cns:EnableLuaFormatter(self.CodeEditBox)

  local numbers = self.Gutter.ScrollChild.Numbers

  -- SetEnabled is the real read-only switch, not enableKeyboard.
  numbers:SetEnabled(false)
  -- LEFT, not RIGHT: the numbers are padded to a common width (see GutterDigits).
  numbers:SetJustifyH('LEFT')
  -- TOP keeps row 1 at the top when the box is taller than its text (short files).
  numbers:SetJustifyV('TOP')
  numbers:SetTextInsets(0, GUTTER_TEXT_RIGHT_INSET, 0, 0)

  self:OnLoad_Border()

  -- todo: will come from settings in the future
  --local name = cns.addon .. ' Dark Knight'
  local th = bdrops.theme
  local name = th.Oakframe
  self:ApplyTheme(name)

  if self.SetResizeBounds then -- WoW 10.0+
    self:SetResizeBounds(400, 250)
  else
    self:SetMinResize(400, 250)
  end

  self:OnLoad_ScaleWatcher()

  self.HeaderTitle = self.Header.Title.Text
  self.CloseButton = self.Header.CloseFrame.CloseButton
  -- Wired in Lua: inherited OnClick hides CloseFrame, not the dialog.
  self.CloseButton:SetScript('OnClick', function() self:OnClickClose() end)

  self.HeaderTitle:SetText('Code Editor (Prototype)')

  self.OptionsButton = self.TopBar.OptionsButton

  --- @type DropdownButton
  self.ThemeButton = self.TopBar.ThemeButton
  self.FontButton = self.TopBar.FontButton
  self.FontSizeButton = self.TopBar.FontSizeButton
  -- Static placeholder items, no action wired yet.
  self.OptionsButton:SetupMenu(function(_, rootDescription)
    rootDescription:CreateButton('Options', function() end)
    rootDescription:CreateButton('Results Inspector', function() end)
  end)

  self:OnLoad_OptionsButton()
  self:OnLoad_ThemeButton()
  self:OnLoad_FontSteppers()
  self:OnLoad_Fonts()
  self:OnLoad_WrapCheckButton()
  self:OnLoad_CodeEditBox()
  self:OnLoad_StatusBar()
  self:OnLoad_CommandBar()

  -- Prototype-only: pre-fill to test gutter/scroll sync on open.
  if ns.EXAMPLE_CODE then self:SetText(ns.EXAMPLE_CODE) end

  self:RefreshGutter()
  --self:OnLoad_Tmp_NineSliceDemo()
end

function o:OnLoad_Tmp_NineSliceDemo()
  -- Demo: NineSlice "ButtonFrameTemplateNoPortrait" layout (EventTrace-style border art)
  local nineSlice = CreateFrame('Frame', nil, UIParent)
  nineSlice:SetSize(500, 300)
  nineSlice:SetPoint('CENTER', UIParent, 0, 0)
  --local bg = nineSlice:CreateTexture(nil, "BACKGROUND")
  --bg:SetTexture([[Interface\FrameGeneral\UI-Background-Rock]], true, true)
  --bg:SetPoint("TOPLEFT", 6, -21)
  --bg:SetPoint("BOTTOMRIGHT", -2, 2)

  --local titleBg = nineSlice:CreateTexture(nil, "BACKGROUND", nil, -6)
  --titleBg:SetAtlas([[_UI-Frame-TitleTileBg]], true)
  --titleBg:SetPoint("TOPLEFT", 6, -3)
  --titleBg:SetPoint("TOPRIGHT", -2, -3)
  --titleBg:SetHeight(20)

  local titleText = nineSlice:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  titleText:SetWordWrap(false)
  titleText:SetPoint('TOP', 0, -10)
  --titleText:SetPoint("LEFT", titleBg, "LEFT")
  --titleText:SetPoint("RIGHT", titleBg, "RIGHT")
  titleText:SetText('Code Editor')
  local myLayout = {
    TopLeftCorner = { atlas = 'CharacterCreateDropdown-NineSlice-CornerTopLeft', x = -30, y = 20 },
    TopRightCorner = { atlas = 'CharacterCreateDropdown-NineSlice-CornerTopRight', x = 30, y = 20 },
    BottomLeftCorner = {
      atlas = 'CharacterCreateDropdown-NineSlice-CornerBottomLeft',
      x = -30,
      y = -20,
    },
    BottomRightCorner = {
      atlas = 'CharacterCreateDropdown-NineSlice-CornerBottomRight',
      x = 30,
      y = -20,
    },
    TopEdge = { atlas = '_CharacterCreateDropdown-NineSlice-EdgeTop' },
    BottomEdge = { atlas = '_CharacterCreateDropdown-NineSlice-EdgeBottom' },
    LeftEdge = { atlas = '!CharacterCreateDropdown-NineSlice-EdgeLeft' },
    RightEdge = { atlas = '!CharacterCreateDropdown-NineSlice-EdgeRight' },
    Center = { atlas = 'CharacterCreateDropdown-NineSlice-Center' },
  }

  --NineSliceUtil.ApplyLayoutByName(nineSlice, 'CharacterCreateDropdown')
  NineSliceUtil.ApplyLayout(nineSlice, myLayout)

  nineSlice:Show()
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
  self.StatusDivider.MinimizeButton:SetPoint('BOTTOMRIGHT', self.ScrollFrame, 'BOTTOMRIGHT', -(i - 3.3), i)
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
  AddTooltip(button, 'Wrap Text')
end

function o:OnLoad_StatusBar()
  self.StatusBar:SetHeight(STATUS_BAR_HEIGHT)
  local divider = self.StatusDivider
  divider.MaximizeButton:SetScript('OnClick', function() self:MaximizeStatus() end)
  divider.MinimizeButton:SetScript('OnClick', function() self:MinimizeStatus() end)
  RotateArrow(divider.MinimizeButton, math.pi / 2)
  RotateArrow(divider.MaximizeButton, -math.pi / 2)
  AddTooltip(divider.MaximizeButton, 'Maximize Output')
  AddTooltip(divider.MinimizeButton, 'Minimize Output')
  self:OnLoad_DividerTooltip()
  self:OnLoad_EvalStatus()
  self:ClearOutput()
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

--- Read-only: outputLines is the only text source.
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
  self.CommandBar.Prompt:SetText('> ')
  self.CommandEditBox:SetAutoFocus(false)
  AddTooltip(self.CommandEditBox, 'Command Line')
end

--- A too-wide dialog must shrink to fit; clampedToScreen can't move it in.
function o:OnLoad_ScaleWatcher()
  self.ScaleWatcher = CreateFrame('Frame')
  self.ScaleWatcher:RegisterEvent('UI_SCALE_CHANGED')
  self.ScaleWatcher:RegisterEvent('DISPLAY_SIZE_CHANGED')
  self.ScaleWatcher:SetScript('OnEvent', function() self:ClampToScreen(true) end)
end

--- Re-asserted on every SetAtlas call, which resets size via useAtlasSize.
function o:OnLoad_OptionsButton()
  local arrow = self.OptionsButton.Arrow
  if not arrow then return end
  local function SizeArrow() arrow:SetSize(OPTIONS_ARROW_SIZE, OPTIONS_ARROW_SIZE) end
  SizeArrow()
  hooksecurefunc(arrow, 'SetAtlas', SizeArrow)
end

function o:OnLoad_ThemeButton()
  self.ThemeButton.Background:Hide()
  self.ThemeButton.Arrow:Hide()
  self.ThemeButton.Text:Hide()

  --- @param rootDescription RootMenuDescriptionProxy
  self.ThemeButton:SetupMenu(function(_, rootDescription)
    local function addRadio(name)
      rootDescription:CreateRadio(
        name,
        function() return name and str_eq(self.borderStyle, name) end,
        function() self:ApplyTheme(name) end
      )
    end
    bdrops:EachTheme(addRadio, function(name) return name and name:lower() ~= 'none' end)
  end)
  -- Theme names are registry keys, so menu entries stay untranslated.
  AddTooltip(self.ThemeButton, 'Theme')
end

function o:OnLoad_Fonts()
  self.FontButton.Background:Hide()
  self.FontButton.Arrow:Hide()
  self.FontButton.Text:Hide()
  self.FontButton:SetupMenu(function(_, rootDescription)
    for _, choice in ipairs(fontChoices) do
      -- CreateButton never checks IsSelected() -- only CreateRadio draws
      -- a checkmark for the current selection.
      rootDescription:CreateRadio(
        choice.label,
        function() return self.fontFamily == choice.key end,
        function() self:SetCodeFont(choice.key, true) end
      )
    end
  end)
  self.FontSizeButton.Background:Hide()
  self.FontSizeButton.Arrow:Hide()
  self.FontSizeButton.Text:Hide()
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
  self.fontSize = DEFAULTS.fontSize
  self:SetCodeFont(DEFAULTS.fontFamily)
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

  -- Selection anchor only moves on a plain (non-shift) cursor change.
  local editBox = self.CodeEditBox
  local current = editBox:GetCursorPosition()
  if IsShiftKeyDown() and self.cursorAnchor then
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

--- User-driven change (checkbox click) -- notify listeners.
--- @param checked boolean
function o:OnWrapToggled(checked) self:SetWrapText(checked, true) end

--- @param name string? @LSM border media name
function o:ApplyTheme(name)
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
  local gutterBorderColor = GUTTER.borderColor
  local code = bs.code

  if code and code.backdrop then
    local cbd = code.backdrop
    local gutter = code.gutter
    local bgColor = cbd.bgColor
    local borderColor = cbd.borderColor

    self.GutterBackdrop:SetBackdrop(cbd)
    self.CodeBackdrop:SetBackdrop(cbd)
    self.StatusBar:SetBackdrop(cbd)
    self.CommandBar:SetBackdrop(cbd)

    if bgColor then
      self.CodeBackdrop:SetBackdropColor(upk(bgColor))
      self.StatusBar:SetBackdropColor(upk(bgColor))
      self.CommandBar:SetBackdropColor(upk(bgColor))
    end
    if borderColor then
      self.CodeBackdrop:SetBackdropBorderColor(upk(borderColor))
      self.StatusBar:SetBackdropBorderColor(upk(borderColor))
      self.CommandBar:SetBackdropBorderColor(upk(borderColor))
      if GUTTER.useCodeBorderColor then gutterBorderColor = borderColor end
    end
    if gutter and gutter.textColor then gutterTextColor = gutter.textColor end
  end
  -- Grip color is tuned per theme; code.backdrop.borderColor alpha is too low here.
  local status = bs.status
  local divider = status.divider
  -- Both remembered so OnStatusDividerHover can swap between them.
  self.statusGripColor = divider.gripColor
  self.statusGripHoverColor = divider.gripHoverColor
  self.StatusDivider.Grip:SetColorTexture(upk(divider.gripColor))
  self.StatusDivider.MaximizeButton.NormalTexture:SetVertexColor(upk(divider.arrowColor))
  self.StatusDivider.MinimizeButton.NormalTexture:SetVertexColor(upk(divider.arrowColor))
  self.EvalStatus:SetTextColor(upk(status.textColor))
  self.CommandBar.Prompt:SetTextColor(upk(status.textColor))
  self.CommandEditBox:SetTextColor(upk(status.textColor))
  -- gutter borderColor is alpha 0 (hidden)
  self.GutterBackdrop:SetBackdropBorderColor(upk(gutterBorderColor))
  self.GutterBackdrop:SetBackdropColor(upk(GUTTER.bgColor))
  self.Gutter.ScrollChild.Numbers:SetTextColor(upk(gutterTextColor))
  self:_SetHeaderBorderStyle(bs)
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
--- @param notify boolean|nil Fire OnConfigChanged (user-driven change); omit for internal/initial sets
function o:SetCodeFont(fontFamily, notify)
  local choice = fut:FindFontChoice(fontFamily)
  if not choice then return end
  self.fontFamily = choice.key
  self:ApplyCodeFont(notify)
end

--- Re-resolves and applies the font for the current fontFamily/fontSize.
--- @param notify boolean|nil Fire OnConfigChanged (user-driven change); omit for internal/initial sets
function o:ApplyCodeFont(notify)
  local choice = fut:FindFontChoice(self.fontFamily)
  if not choice then return end
  local font = choice.bySize[self.fontSize] or choice.bySize[DEFAULTS.fontSize]
  self.codeFont = font

  -- EditBox has its own SetFontObject/SetFont/GetFont, no GetFontString().
  self.CodeEditBox:SetFontObject(font)
  self.Gutter.ScrollChild.Numbers:SetFontObject(font)
  self.WrapMeasure.Text:SetFontObject(font)

  -- Must set justify here: SetFontObject resets it.
  self.EvalStatus:SetFontObject(font)
  self.EvalStatus:SetJustifyH('LEFT')

  self.CommandBar.Prompt:SetFontObject(font)
  self.CommandEditBox:SetFontObject(font)

  -- Gray out the steppers at the size list ends.
  local sizes = fut:GetFontSizes()
  local canShrink, canGrow = self.fontSize ~= sizes[1], self.fontSize ~= sizes[#sizes]
  C_Timer.After(0.1, function()
    self.FontSteppers.MinusButton:SetEnabled(canShrink)
    self.FontSteppers.PlusButton:SetEnabled(canGrow)
  end)

  -- RefreshGutter re-sizes the gutter for the new font's digit width.
  self:RefreshGutter()
  if notify then self:FireConfigChanged() end
end

--- Sets the font size (snapped to the nearest supported size) and re-applies
--- the current font family at that size.
--- @param fontSize number
--- @param notify boolean|nil Fire OnConfigChanged (user-driven change); omit for internal/initial sets
function o:SetFontSize(fontSize, notify)
  self.fontSize = fut:NearestFontSize(fontSize)
  self:ApplyCodeFont(notify)
end

--- Steps the font size, clamped at the ends. Always user-driven; notifies.
--- @param delta number 1 to step up, -1 to step down
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
--- @param notify boolean|nil Fire OnConfigChanged (user-driven change); omit for internal/initial sets
function o:SetWrapText(enabled, notify)
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
  if notify then self:FireConfigChanged() end
end

--- @return LDK_CodeEditorOptions Current settings, regardless of what (if anything) just changed
function o:GetOptions()
  return {
    fontFamily = self.fontFamily,
    fontSize = self.fontSize,
    wrapText = self.wrapText,
  }
end

--- Callback after user config changes; always gets a full options snapshot.
--- @param callback fun(self: LDK_CodeEditorDialog, options: LDK_CodeEditorOptions)|nil
function o:SetOnConfigChanged(callback) self.onConfigChanged = callback end

function o:FireConfigChanged()
  if self.onConfigChanged then self.onConfigChanged(self, self:GetOptions()) end
end

--- Merges partial settings over current; does not fire OnConfigChanged.
--- @param options LDK_CodeEditorOptions|table|nil Partial table; omitted fields keep their current value
function o:Configure(options)
  options = options or {}
  -- Falls back if the key no longer resolves (e.g. a removed font family).
  local fontFamily = options.fontFamily or self.fontFamily or DEFAULTS.fontFamily
  if not fut:FindFontChoice(fontFamily) then fontFamily = DEFAULTS.fontFamily end
  self.fontFamily = fontFamily
  self.fontSize = fut:NearestFontSize(options.fontSize or self.fontSize or DEFAULTS.fontSize)
  local wrapText = options.wrapText
  if wrapText == nil then wrapText = self.wrapText end
  if wrapText == nil then wrapText = DEFAULTS.wrapText end

  self:ApplyCodeFont()
  self:SetWrapText(wrapText)
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
function o:SetStatusHeight(height)
  local maxHeight = MaxStatusHeight(self)
  height = Clamp(height, MIN_STATUS_HEIGHT, maxHeight)
  if SizeDiffers(self.StatusBar:GetHeight(), height) then self.StatusBar:SetHeight(height) end
  -- Disable the arrow for whichever end the panel is already at.
  local divider = self.StatusDivider
  UpdateArrowState(divider.MaximizeButton, SizeDiffers(height, maxHeight))
  UpdateArrowState(divider.MinimizeButton, SizeDiffers(height, MIN_STATUS_HEIGHT))
end

--- @return number
function o:GetStatusHeight() return self.StatusBar:GetHeight() end

--- Grows the output panel as far as MIN_CODE_HEIGHT allows (the up arrow).
function o:MaximizeStatus() self:SetStatusHeight(MaxStatusHeight(self)) end

--- Shrinks the output panel to MIN_STATUS_HEIGHT (the down arrow).
function o:MinimizeStatus() self:SetStatusHeight(MIN_STATUS_HEIGHT) end

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
  self:SetStatusHeight(divider.heightStart + delta)
end

--- @param hovered boolean
function o:OnStatusDividerHover(hovered)
  local color = hovered and self.statusGripHoverColor or self.statusGripColor
  self.StatusDivider.Grip:SetColorTexture(upk(color))
end

--- Drops every line of output collected so far.
function o:ClearOutput()
  self.outputLines = {}
  self:RefreshOutput()
end

--- Rewrites the output box from outputLines.
function o:RefreshOutput()
  local box = self.EvalStatus
  local child = self.OutputScrollFrame.ScrollChild
  -- Scroll children ignore right anchors; set width here.
  local width = self.OutputScrollFrame:GetWidth()
  -- Zero until the first layout pass; OnSizeChanged retries.
  if width > 0 and SizeDiffers(child:GetWidth(), width) then child:SetWidth(width) end
  self:SyncOutputHeight()

  -- A divider drag re-enters this every frame.
  local text = table.concat(self.outputLines or {}, '\n')
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
  local lines = self.outputLines or {}
  -- Trailing '\n' keeps a final empty line, matching CountLines().
  for line in (tostring(text or '') .. '\n'):gmatch('(.-)\n') do
    lines[#lines + 1] = line
  end
  local excess = #lines - MAX_OUTPUT_LINES
  if excess > 0 then
    -- Shift survivors down instead of rebuilding the table each append.
    for i = 1, #lines - excess do
      lines[i] = lines[i + excess]
    end
    for i = #lines - excess + 1, #lines do
      lines[i] = nil
    end
  end
  self.outputLines = lines
  self:RefreshOutput()
end

--- @return string Everything currently shown in the output panel
function o:GetOutput() return table.concat(self.outputLines or {}, '\n') end

--[[-----------------------------------------------------------------------------
Command line: single-shot eval; no multi-line continuation
-------------------------------------------------------------------------------]]
--- Grey, comma-joined print output, matching WowLua's own wowpad_print.
--- @param self LDK_CodeEditorDialog
local function CommandPrint(self, ...)
  local parts = {}
  for i = 1, select('#', ...) do
    parts[i] = tostring(select(i, ...))
  end
  self:AppendOutput('|cff999999' .. table.concat(parts, ', ') .. '|r')
end

--- Runs one line from the command bar and appends every outcome -- the echoed
--- input, a compile error, a runtime error, or printed output -- to the same
--- output panel a full Run uses.
--- @param text string
function o:OnCommandEnterPressed(text)
  if str_isBlank(text) then return end

  -- Escape literal '|' so the echoed input can't be read as a color/texture code.
  self:AppendOutput(self.CommandBar.Prompt:GetText() .. text:gsub('|', '||'))

  -- '= expr' shorthand, same as WowLua's console.
  local expr = text:match('^%s*=%s*(.+)$')
  local func, err = loadstring(expr and ('print(' .. expr .. ')') or text)

  -- Not '= expr' syntax, but maybe still a bare expression -- retry the same
  -- way WowLua's console does, so e.g. typing "5 + 5" alone still prints.
  if not func and not expr then
    local retryFunc = loadstring('print(' .. text .. ')')
    if retryFunc then func, err = retryFunc, nil end
  end

  if not func then
    self:AppendOutput('|cffff0000' .. err .. '|r')
    return
  end

  local oldPrint = print
  print = function(...) CommandPrint(self, ...) end
  local ok, runErr = pcall(func)
  print = oldPrint

  if not ok then self:AppendOutput('|cffff0000' .. runErr .. '|r') end
end

--- @return string
function o:GetText() return self.CodeEditBox:GetText() end

--- Text past MAX_LINES is dropped; unbounded truncated the gutter before.
--- @param text string
function o:SetText(text)
  self.CodeEditBox:SetText(TrimToMaxLines(text or ''))
  self:RefreshGutter()
end
