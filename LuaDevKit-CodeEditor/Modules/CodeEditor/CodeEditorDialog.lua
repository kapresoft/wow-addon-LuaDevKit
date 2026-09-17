--[[-----------------------------------------------------------------------------
CodeEditorDialog: standalone (non-Ace3) line-numbered code editor prototype.
Self-contained: not wired into the DevSuite namespace/module registry.
See GitHub issue #90.
-------------------------------------------------------------------------------]]
--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local cns, O = ns:cns(), ns:cns().O
local DB, bdrops = O.Database, O.Backdrops
local fut, LSM, FAIAP = O.FontUtil, O.LSM, O.FAIAP
local str_eq = O.String.EqualsIgnoreCase

local libName = "CodeEditorDialog"

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local CreateFrame = CreateFrame
local strlenutf8 = strlenutf8

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]

local DEFAULT_BORDER_SETTINGS = bdrops:GetBorderSettings()

-- Fewest digits the gutter is sized for, so a short file's gutter doesn't
-- widen again the moment it reaches line 10.
local MIN_GUTTER_DIGITS = 2

-- Longest snippet this editor holds. It is a scratchpad for prototyping code
-- in-game, not a file editor; text past this is dropped on the way in.
local MAX_LINES = 3000

-- Horizontal room around the digits inside GutterBackdrop: the Gutter
-- ScrollFrame is inset 5px on each side (XML), the numbers EditBox has a 4px
-- right text inset (OnLoad), plus 4px of left margin.
local GUTTER_PADDING = 5 + 5 + 4 + 4

-- Draws the gutter's border in the same backdrop as the code area, so the
-- line-number column's bounds are visible while working on its layout.
local SHOW_GUTTER_OUTLINE = true

-- Width of the gutter's numbers EditBox; only needs to exceed any gutter width.
local NUMBERS_BOX_WIDTH = 500

-- Extra room beyond the measured digit width, since an EditBox needs more than
-- its text area's arithmetic suggests before it will render a line.
local GUTTER_SLACK = 0

-- Breathing room left when the dialog is clamped to the screen, on whichever
-- axis had to shrink: total, so the usable extent is the screen's minus this.
local SCREEN_MARGIN = 100

local fontChoices = fut:GetFontChoices()
--local defaultFontChoice = #fontChoices > 0 and fontChoices[1]
local defaultFontChoice = fut:GetDefaultFontChoice()

-- Configure() defaults, and the shape of the snapshot passed to the
-- OnConfigChanged callback.
local DEFAULTS = {
	-- A literal key, not cns:GetFonts()[1].key: that call builds every font
	-- object via CreateFont/SetFont, and doing that this early (this table is
	-- built as soon as this file's top-level code runs, well before the
	-- client's asset system is ready for custom font files) makes SetFont
	-- fail with "file not found" even though the same path works fine once the
	-- dialog is actually opened later in the session.
	fontFamily = defaultFontChoice and defaultFontChoice.key,
	fontSize = 14,
	wrapText = false,
}

--[[-----------------------------------------------------------------------------
Backdrops
-------------------------------------------------------------------------------]]
local HEADER_BACKDROP = {
	--bgFile = "Interface\\FrameGeneral\\UI-Background-Rock",
	--bgFile = "Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground",
	-- Flat white 8x8 (the same texture LibSharedMedia registers as its "Solid"
	-- background/statusbar) so SetBackdropColor's tint isn't multiplied against
	-- art detail -- white * color = that exact color.
	bgFile = [[Interface\Buttons\WHITE8X8]],
	edgeFile = [[Interface\FriendsFrame\UI-Toast-Border]],
	tile = true,
	tileEdge = true,
	tileSize = 4,
	edgeSize = 8,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

--- @deprecated
local MAIN_BACKDROP = {
	bgFile = [[Interface\FriendsFrame\UI-Toast-Background]],
	edgeFile = [[Interface\FriendsFrame\UI-Toast-Border]],
	tile = true,
	tileEdge = true,
	tileSize = 4,
	edgeSize = 8,
	insets = { left = 3, right = 3, top = 4, bottom = 3 },
}

local TOP_AND_BOTTOM_BACKDROP = {
	bgFile = [[Interface\FriendsFrame\UI-Toast-Background]],
	tile = false,
	tileSize = 0,
	edgeSize = 0,
	insets = { left = 8, right = 8, top = 12, bottom = 8 },
}

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_CodeEditorGutterChild : Frame
--- @field Numbers EditBox Read-only "1\n2\n...\nN" in the code font, right-justified

--- @class LDK_CodeEditorGutter : ScrollFrame
--- @field ScrollChild LDK_CodeEditorGutterChild

--- @class LDK_CodeEditorBottomBar : Frame
--- @field WrapCheckButton CheckButton

--- @class LDK_CodeEditorHeaderTitle : Frame
--- @field Text FontString The dialog title, centered

--- @class LDK_CodeEditorHeaderCloseFrame : Frame
--- @field CloseButton Button

--- @class LDK_CodeEditorHeader : Frame
--- @field Title LDK_CodeEditorHeaderTitle Fluid: absorbs all width left by CloseFrame
--- @field CloseFrame LDK_CodeEditorHeaderCloseFrame Fixed 32px, pinned right

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
--- @field HeaderTitle FontString
--- @field borderStyle Name
LDK_CodeEditorDialogMixin = {}
local o = LDK_CodeEditorDialogMixin

--
--- @class LDK_CodeEditorDialog : LDK_CodeEditorDialogMixin
--

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Sub-pixel differences are noise; only treat a real change as a change. WoW
--- re-fires OnSizeChanged/OnTextChanged even when nothing actually changed, so
--- every resize and every refresh is gated on this to keep those events from
--- feeding each other every frame.
--- @param current number|nil
--- @param wanted number
--- @return boolean
local function SizeDiffers(current, wanted)
	return math.abs((current or 0) - wanted) > 0.5
end

--- @param self LDK_CodeEditorDialog
--- @return number
local function CountLines(self)
	local text = self.CodeEditBox:GetText() or ""
	local _, count = text:gsub("\n", "\n")
	return count + 1
end

--- Lines that fit in one viewport, for Page Up/Down: floor(viewport height /
--- line height), so a page-jump moves exactly as far as what's currently
--- visible. Cmd+Page Up/Down jumps twice that.
--- @param self LDK_CodeEditorDialog
--- @return number
local function ViewportLines(self)
	return math.max(1, math.floor(self.ScrollFrame:GetHeight() / self.WrapMeasure.Text:GetLineHeight()))
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
			local nl = text:find("\n", pos + 1, true)
			if not nl then
				pos = #text
				break
			end
			pos = nl
		else
			-- Same landing convention as the forward branch (on the '\n'
			-- itself, not one character before it): landing short drifted
			-- the search window by one character each iteration, compounding
			-- into visibly wrong lines over several Page Up presses.
			local nl
			for p in text:sub(1, pos - 1):gmatch("()\n") do
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

	-- Scroll by the same number of lines the cursor moved, so the cursor's
	-- row position within the viewport (e.g. 5 lines down from the top)
	-- stays the same after the jump -- not "snap to nearer edge" (the
	-- generic scroll-to-caret) and not "always land at the top." `crossed`
	-- (not `lines`) since a jump near the document's start/end moves fewer
	-- lines than requested.
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
	for line in (text .. "\n"):gmatch("(.-)\n") do
		count = count + 1
		if count > MAX_LINES then
			break
		end
		kept[count] = line
	end
	return table.concat(kept, "\n")
end

--- @param numLines number
--- @return string text "1\n2\n...\nN"
--- @return number rows Rendered row count, for sizing the gutter
local function LineNumbersText(numLines)
	local parts = {}
	for i = 1, numLines do
		parts[i] = i
	end
	return table.concat(parts, "\n"), numLines
end

--- Wrap mode: each logical line gets its number followed by (rows - 1) blank
--- lines, so the gutter's rows mirror the code's wrapped visual rows.
--- @param self LDK_CodeEditorDialog
--- @return string text
--- @return number rows Rendered row count, for sizing the gutter
local function WrappedLineNumbersText(self)
	local measure = self.WrapMeasure.Text
	local parts = {}
	local n = 0
	-- Trailing '\n' keeps a final empty line counted, matching CountLines().
	for line in (self.CodeEditBox:GetText() .. "\n"):gmatch("(.-)\n") do
		n = n + 1
		parts[#parts + 1] = n
		measure:SetText(line)
		local rows = measure:GetNumLines()
		for _ = 2, rows do
			parts[#parts + 1] = ""
		end
	end
	return table.concat(parts, "\n"), #parts
end

--- GutterBackdrop width that fits the highest line number in the current font.
--- Measured on WrapMeasure's FontString (same font as the gutter); every
--- catalog font is monospace, so a run of zeros is as wide as any number with
--- that many digits.
--- @param self LDK_CodeEditorDialog
--- @param lastLine number Highest line number the gutter shows
--- @return number
local function GutterWidth(self, lastLine)
	local digits = math.max(#tostring(lastLine), MIN_GUTTER_DIGITS)
	local measure = self.WrapMeasure.Text
	measure:SetText(string.rep("0", digits))
	-- Measured width plus GUTTER_SLACK: an EditBox needs more room for a line
	-- than its width minus text insets suggests (at size 10, a 26px 4-digit
	-- number still wrapped in a 31px text area), and a line that doesn't fit
	-- ends that EditBox's rendering at "..." -- taking every line below it with
	-- it. The slack is deliberately generous; too wide only costs a little
	-- unused column, too narrow breaks the whole gutter.
	return math.ceil(measure:GetStringWidth()) + GUTTER_SLACK + GUTTER_PADDING
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
	self:OnLoad_GripLines()

	-- parentKey="CodeEditBox" resolves onto the ScrollFrame (its immediate XML
	-- parent), not this dialog frame -- alias it here so the rest of this file
	-- can address it as self.CodeEditBox.
	self.CodeEditBox = self.ScrollFrame.CodeEditBox
	cns:EnableLuaFormatter(self.CodeEditBox)

	-- UIPanelScrollFrameTemplate's ScrollBar anchors at y=-16/16 (SecureScrollTemplates.xml),
	-- leaving a gap above/below the up/down arrow buttons at this frame's height.
	-- Re-anchoring in XML would need the whole ScrollBar (and its ScrollUpButton/
	-- ScrollDownButton/ThumbTexture children) redeclared with matching $parent names to
	-- merge instead of duplicating, so adjust the existing scrollbar here instead.
	local scrollBar = self.ScrollFrame.ScrollBar
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOPLEFT", self.ScrollFrame, "TOPRIGHT", 6, -11)
	scrollBar:SetPoint("BOTTOMLEFT", self.ScrollFrame, "BOTTOMRIGHT", 6, 10)

	-- Gutter numbers EditBox: no justifyH attribute exists for EditBox in XML, so
	-- justify here; the right inset keeps digits off the gutter's clip edge.
	local numbers = self.Gutter.ScrollChild.Numbers

	-- enableKeyboard="false" (XML) only blocks the box from acquiring focus on
	-- its own; it does not refuse input once focused some other way. SetEnabled
	-- is the actual read-only switch.
	numbers:SetEnabled(false)
	numbers:SetJustifyH("RIGHT")

	-- Right inset absorbs the EditBox's 10px right-shift (XML anchors) on top of
	-- the 4px margin, so the right-justified digits land back inside the Gutter's
	-- clip edge instead of just outside it.
	numbers:SetTextInsets(0, 4, 0, 0)

	-- An EditBox needs more room for a line than its width minus insets
	-- suggests, and a line that doesn't fit stops its rendering at "...". So the
	-- box is made far wider than any gutter, right-anchored (XML), and the
	-- Gutter clips the unused left side.
	numbers:SetWidth(NUMBERS_BOX_WIDTH)

	local headerColor = CreateColorFromRGBHexString("151B2B")
	--self.Header:SetBackdropColor(0.2275, 0.2157, 0.2314, .95)
	self.Header:SetBackdropColor(headerColor:GetRGBA())

  -- todo: will come from settings in the future
  local name = 'Default'
  self:SetBorderStyle(name)

	if self.SetResizeBounds then -- WoW 10.0+
		self:SetResizeBounds(400, 250)
	else
		self:SetMinResize(400, 250)
	end

	self:OnLoad_ScaleWatcher()

	-- Header children: parentKey resolves onto the immediate XML parent (Title /
	-- CloseFrame), not this dialog frame -- alias them, same as CodeEditBox above.
	self.HeaderTitle = self.Header.Title.Text
	self.CloseButton = self.Header.CloseFrame.CloseButton
	-- Wired here rather than in XML: UIPanelCloseButton inherits an OnClick that
	-- hides GetParent(), which is now CloseFrame, not the dialog.
	self.CloseButton:SetScript("OnClick", function()
		self:OnClickClose()
	end)

	self.HeaderTitle:SetText("Code Editor (Prototype)")

	-- parentKey="OptionsButton"/"BorderButton"/"FontButton"/"FontSizeButton"/
	-- "FontSizeUpButton"/"FontSizeDownButton" resolve onto TopBar (their
	-- immediate XML parent), not this dialog frame -- alias them here, same as
	-- CodeEditBox above.
	self.OptionsButton = self.TopBar.OptionsButton

	--- @type DropdownButton
	self.BorderButton = self.TopBar.BorderButton
	self.FontButton = self.TopBar.FontButton
	self.FontSizeButton = self.TopBar.FontSizeButton
	self.FontSizeUpButton = self.TopBar.FontSizeUpButton
	self.FontSizeDownButton = self.TopBar.FontSizeDownButton
	-- Static placeholder items, no action wired yet.
	self.OptionsButton:SetupMenu(function(_, rootDescription)
		rootDescription:CreateButton("Options", function() end)
		rootDescription:CreateButton("Results Inspector", function() end)
	end)

	self:OnLoad_BorderButton()
	self:OnLoad_Fonts()
	self.BottomBar.WrapCheckButton.text:SetText("Wrap Text")
	self:OnLoad_CodeEditBox()

	-- Prototype-only: pre-fill with sample code long enough to force scrolling,
	-- so gutter/scroll sync can be tested immediately on open.
	if ns.EXAMPLE_CODE then self:SetText(ns.EXAMPLE_CODE) end

	self:RefreshGutter()
end

--- Default is no-wrap: the EditBox is fixed-width and wider than the scroll
--- viewport, so lines never reach a wrap boundary and logical line count
--- (\n-based) always equals visual line count. Start at the viewport's
--- height (not 1px) so there's a clickable/visible area before any text
--- is typed; RefreshGutter grows it from here as needed.
function o:OnLoad_CodeEditBox()
	self.CodeEditBox:SetHeight(self.ScrollFrame:GetHeight())
	self.CodeEditBox:SetAutoFocus(false)
	self:SetWrapText(DEFAULTS.wrapText)
	-- Horizontal text padding: EditBox insets are the actual API for this --
	-- the frame's own anchors position the whole (4000px-wide, no-wrap) hit
	-- region, not the glyphs within it, so nudging those anchors doesn't pad
	-- the text. Top/bottom stay 0 -- the gutter's line labels are positioned
	-- independently of CodeEditBox's insets, so a vertical inset here would
	-- desync line 1's label from the code's actual first line.
	self.CodeEditBox:SetTextInsets(6, 6, 0, 0)
end

--- clampedToScreen only constrains position, so a dialog left wider than the
--- screen (sized at a high UI scale, then scaled down) can't be nudged back
--- into view by moving alone -- it has to shrink.
function o:OnLoad_ScaleWatcher()
	self.ScaleWatcher = CreateFrame("Frame")
	self.ScaleWatcher:RegisterEvent("UI_SCALE_CHANGED")
	self.ScaleWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
	self.ScaleWatcher:SetScript("OnEvent", function()
		self:ClampToScreen(true)
	end)
end

--- Icon-only: hide WowStyle1DropdownTemplate's own text-button chrome so
--- just this frame's own NormalTexture (set in XML) shows, matching
--- FontSizeButton's look.
function o:OnLoad_BorderButton()
	self.BorderButton.Background:Hide()
	self.BorderButton.Arrow:Hide()
	self.BorderButton.Text:Hide()

	--- @param rootDescription RootMenuDescriptionProxy
	self.BorderButton:SetupMenu(function(_, rootDescription)
		local function addRadio(name)
			rootDescription:CreateRadio(name, function()
				return str_eq(self.borderStyle, name)
			end, function()
				self:SetBorderStyle(name)
			end)
		end
		addRadio('Default')
		bdrops:ForEachBorder(addRadio, function(name)
			return name:lower() == 'none'
		end)
	end)

end

function o:OnLoad_Fonts()
	self.FontButton.Background:Hide()
	self.FontButton.Arrow:Hide()
	self.FontButton.Text:Hide()
	self.FontButton:SetupMenu(function(_, rootDescription)
		for _, choice in ipairs(fontChoices) do
			-- CreateButton never checks IsSelected() -- only CreateRadio draws
			-- a checkmark for the current selection.
			rootDescription:CreateRadio(choice.label, function()
				return self.fontFamily == choice.key
			end, function()
				self:SetCodeFont(choice.key, true)
			end)
		end
	end)
	self.FontSizeButton.Background:Hide()
	self.FontSizeButton.Arrow:Hide()
	self.FontSizeButton.Text:Hide()
	self.FontSizeButton:SetupMenu(function(_, rootDescription)
		for _, size in ipairs(fut:GetFontSizes()) do
			rootDescription:CreateRadio(tostring(size), function()
				return self.fontSize == size
			end, function()
				self:SetFontSize(size, true)
			end)
		end
	end)
	self.FontSizeUpButton:SetScript("OnClick", function()
		self:StepFontSize(1)
	end)
	self.FontSizeDownButton:SetScript("OnClick", function()
		self:StepFontSize(-1)
	end)
	self.fontSize = DEFAULTS.fontSize
	self:SetCodeFont(DEFAULTS.fontFamily)
end

--- Diagonal resize-grip lines
function o:OnLoad_GripLines()
	local line1 = self.SizerSE.Line1
	local x1 = 0.1 * 14 / 17
	local line1Origin = 0.05
	local line1Center = 0.1
	line1:SetTexCoord(line1Origin - x1, line1Center, line1Origin, line1Center + x1, line1Origin, line1Center - x1, line1Center + x1, line1Center)
	local line2 = self.SizerSE.Line2
	local x2 = 0.1 * 5 / 17
	local line2Origin = 0.032
	local line2Center = 0.40
	line2:SetTexCoord(line2Origin - x2, line2Center, line2Origin, line2Center + x2, line2Origin, line2Center - x2, line2Center + x2, line2Center)
end

--- Raise on every Show, not just on click: toplevel="true" only re-raises on
--- a mouse-down inside the frame, so without this the dialog could still open
--- underneath another DIALOG-strata toplevel frame (e.g. Blizzard_EventTrace)
--- until the user's first click on it.
function o:OnShow()
	self:Raise()
	-- Scale can change while the dialog is hidden, and the watcher's clamp only
	-- fixes the frame's numbers, not what the user sees -- re-clamp on the way in.
	self:ClampToScreen(true)
	-- Testing whether SetFocus() only takes effect once the dialog is actually
	-- visible: OnLoad's SetText ran while this frame was still hidden
	-- (hidden="true" in the template), and SetFocus()/SetCursorPosition(0)
	-- called there did not produce a visible caret. Guarded to first Show only,
	-- so reopening the dialog later doesn't reset wherever the user left off.
	if not self.initialFocusApplied then
		self.initialFocusApplied = true
		self.CodeEditBox:SetFocus()
		self.CodeEditBox:SetCursorPosition(0)
	end
end

--- Shrinks the dialog to fit the usable screen area and pulls it back inside
--- the edges. Both are needed after a UI scale drop: the frame keeps its size
--- in UI units, so a smaller UIParent leaves it overhanging or larger than the
--- screen entirely.
--- @param withMargin boolean|nil Leave SCREEN_MARGIN of room on an axis that has to shrink; omit for a bare screen-edge clamp
function o:ClampToScreen(withMargin)
	local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
	local maxWidth, maxHeight = screenWidth, screenHeight
	local width, height = self:GetWidth(), self:GetHeight()
	-- An axis that no longer fits loses SCREEN_MARGIN and is then centred in
	-- what's left, so the dialog sits with half the margin clear on each side
	-- rather than flush against an edge. Only on this path: a resize grip drag
	-- clamps to the bare screen, since that size is the one the user just chose.
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
	-- Floors are the resize minimums: a screen smaller than those is not worth
	-- distorting the layout for.
	local fitWidth = math.max(400, math.min(width, maxWidth))
	local fitHeight = math.max(250, math.min(height, maxHeight))
	if fitWidth ~= width or fitHeight ~= height then
		self:SetSize(fitWidth, fitHeight)
	end

	-- Re-anchor from the measured rect rather than nudging the existing anchor:
	-- the dialog is moved by StartMoving, so its point is whatever the drag left.
	local left, bottom = self:GetLeft(), self:GetBottom()
	if not left or not bottom then
		return
	end
	-- Bounds run against the full screen with the half-margin held back on each
	-- side, so an axis that shrank keeps its gap top and bottom (or left and
	-- right) instead of being pinned to the edge.
	local clampedLeft = math.max(insetX, math.min(left, screenWidth - fitWidth - insetX))
	local clampedBottom = math.max(insetY, math.min(bottom, screenHeight - fitHeight - insetY))
	if clampedLeft ~= left or clampedBottom ~= bottom then
		self:ClearAllPoints()
		self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", clampedLeft, clampedBottom)
	end
end

function o:OnClickClose()
	self:Hide()
end

--- Escape while the dialog itself has keyboard focus (e.g. after the
--- EditBox cleared its own focus on a first Escape) closes the dialog.
--- @param key string
function o:OnKeyDown(key)
	if key == "ESCAPE" then
		self:OnClickClose()
		self:SetPropagateKeyboardInput(false)
	else
		self:SetPropagateKeyboardInput(true)
	end
end

--- Vertical scroll of the code ScrollFrame moves the gutter's own scroll in
--- lockstep, via the real ScrollFrame API (not a manual re-anchor) so the
--- gutter's content clips to its viewport exactly like the code area's does.
--- @param offset number
function o:OnCodeEditBoxScroll(offset)
	self.Gutter:SetVerticalScroll(offset)
end

function o:OnCodeEditBoxTextChanged()
	-- CodeEditBox's own OnLoad wires this script and can fire it during
	-- construction, before this dialog's OnLoad has aliased self.CodeEditBox.
	if not self.CodeEditBox then
		return
	end

	-- Skip gutter/wrap work while the dialog is hidden (e.g. a future
	-- programmatic SetText call) -- nothing is visible to refresh. OnLoad's own
	-- RefreshGutter() call runs unconditionally before first Show regardless of
	-- what text (if any) was set, so this guard doesn't skip the initial sync.
	if not self:IsShown() then
		return
	end

	-- WoW re-fires OnTextChanged even when the contents did not actually change,
	-- and RefreshGutter resizes the box, which provokes yet more events -- that
	-- cycle ran every frame and kept the caret from ever rendering. Only do the
	-- work when the text really differs.
	local text = self.CodeEditBox:GetText()
	if text == self.lastGutterText then
		return
	end
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

	if target and SizeDiffers(scroll, target) then
		scrollFrame:SetVerticalScroll(target)
	end

	-- Shift+click selection: the anchor is the fixed starting point of the
	-- selection, so it must only move on a plain (non-shift) cursor change --
	-- overwriting it on every change (including shift+clicks) lost the true
	-- start once a second shift+click landed on the opposite side of it.
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

--- PAGEUP/PAGEDOWN: moves the caret one viewport's worth of lines up/down
--- (two with Cmd held). PageMoveCursor scrolls the view by the same line
--- count, so the caret keeps its row position within the viewport instead of
--- just being nudged back into view.
--- @param key "PAGEUP"|"PAGEDOWN"
function o:OnCodeEditBoxPageKey(key)
	local lines = ViewportLines(self)
	if IsMetaKeyDown() then
		lines = lines * 2
	end
	PageMoveCursor(self, key == "PAGEUP" and -1 or 1, lines)
end

--- Cmd+Home / Cmd+End: jumps the caret to the very start/end of the document.
--- SetCursorPosition fires OnCodeEditBoxCursorChanged, which already scrolls
--- the view to keep the caret visible -- no scroll logic needed here.
--- @param key "HOME"|"END"
function o:OnCodeEditBoxDocumentJumpKey(key)
	local editBox = self.CodeEditBox
	if key == "HOME" then
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

--- The ScrollFrame (viewport) resized -- e.g. a SizerSE drag. This is the only
--- size event worth reacting to: RefreshGutter never resizes the ScrollFrame, so
--- it cannot feed itself here, and in wrap mode the viewport's new width is
--- exactly what has to be re-wrapped against. (The EditBox's own OnSizeChanged
--- is intentionally not wired -- RefreshGutter is the only thing that resizes
--- it, so that handler only ever reacted to our own writes and looped.)
function o:OnCodeViewportSizeChanged()
	if not self.CodeEditBox then
		return
	end
	self:RefreshGutter()
end

--- User-driven change (checkbox click) -- notify listeners.
--- @param checked boolean
function o:OnWrapToggled(checked)
	self:SetWrapText(checked, true)
end

--- Applies an LSM-registered border (cns:GetBorders()) as the dialog frame's
--- own backdrop edge (the outer window border). CodeBackdrop/GutterBackdrop
--- stay pinned to LDK_BORDER_DEFS['minimal'] (set once in OnLoad) and are not
--- affected by this.
--- @param name string? LSM border media name, from cns:GetBorders()
function o:SetBorderStyle(name)
  local bs = bdrops:GetBorderSettings(name)
  if not bs then return end
  local main = bs.main
	self.borderStyle = bs.name
	self:SetBackdrop(main.backdrop)
	tr(libName, 'SetBorderStyle', 'showGutterOutline=', bs.showGutterOutline)

  -- editBox Border has its own style
  local code = bs.code
  local editBoxBorder = bdrops.CODE_EDITBOX_BORDER
  self.CodeBackdrop:SetBackdrop(code.backdrop)
  -- CodeBackdrop must use main frame backdrop
  self.CodeBackdrop:SetBackdropColor(unpack(code.bgColor))
  self.CodeBackdrop:SetBackdropBorderColor(unpack(code.borderColor))

  --local bs, numberBackdrop = bdrops:GetBorderSettings(), LDK_BORDER_DEFS['minimal']
  self.GutterBackdrop:SetBackdrop(code.backdrop)
  self.GutterBackdrop:SetBackdropColor(unpack(code.bgColor))

  -- todo: still debating whether bs.showGutterOutline is a border setting property global
  local gutterBdBorderColor = { 0, 0, 0, 0 }
  if bs.showGutterOutline ~= false then gutterBdBorderColor = code.borderColor end
  self.GutterBackdrop:SetBackdropBorderColor(unpack(gutterBdBorderColor))

	-- todo: See what Header looks like synced to the same border style
	--self.Header:SetBackdrop(backdrop)
end

--- Applies a font (by FontUtil font-choice key, at the current fontSize) to
--- the code box, the gutter numbers, and the hidden wrap measuring string
--- together -- inherits="..." in XML only binds once at load, so switching
--- fonts at runtime needs SetFontObject on all three.
--- @param fontFamily string Key into FontUtil:GetFontChoices()
--- @param notify boolean|nil Fire OnConfigChanged (user-driven change); omit for internal/initial sets
function o:SetCodeFont(fontFamily, notify)
	local choice = fut:FindFontChoice(fontFamily)
	if not choice then
		return
	end
	self.fontFamily = choice.key
	self:ApplyCodeFont(notify)
end

--- Re-resolves and applies the font object for the current fontFamily +
--- fontSize pair. Shared by SetCodeFont and SetFontSize -- both change one
--- half of the same (family, size) lookup into FontUtil:GetFontChoices()[].bySize.
--- @param notify boolean|nil Fire OnConfigChanged (user-driven change); omit for internal/initial sets
function o:ApplyCodeFont(notify)
	local choice = fut:FindFontChoice(self.fontFamily)
	if not choice then
		return
	end
	local font = choice.bySize[self.fontSize] or choice.bySize[DEFAULTS.fontSize]
	self.codeFont = font
	-- EditBox:GetFontString() does not exist -- EditBox has its own direct
	-- SetFontObject/SetFont/GetFont API (confirmed against Blizzard's real
	-- EditBox API docs), no need to reach into a child FontString for this.
	self.CodeEditBox:SetFontObject(font)
	self.Gutter.ScrollChild.Numbers:SetFontObject(font)
	self.WrapMeasure.Text:SetFontObject(font)
	-- Disable the step buttons at the ends of FontUtil:GetFontSizes() -- both
	-- templates ship a DisabledTexture for exactly this state.
	local sizes = fut:GetFontSizes()
	self.FontSizeDownButton:SetEnabled(self.fontSize ~= sizes[1])
	self.FontSizeUpButton:SetEnabled(self.fontSize ~= sizes[#sizes])
	-- RefreshGutter re-sizes the gutter for the new font's digit width.
	self:RefreshGutter()
	if notify then
		self:FireConfigChanged()
	end
end

--- Sets the font size (snapped to the nearest supported size) and re-applies
--- the current font family at that size.
--- @param fontSize number
--- @param notify boolean|nil Fire OnConfigChanged (user-driven change); omit for internal/initial sets
function o:SetFontSize(fontSize, notify)
	self.fontSize = fut:NearestFontSize(fontSize)
	self:ApplyCodeFont(notify)
end

--- Moves to the next/previous entry in FontUtil:GetFontSizes(), clamped at
--- the ends. No-ops at a boundary (the step buttons are disabled there too,
--- but this guards against any other caller). User-driven, so notifies.
--- @param delta number 1 to step up, -1 to step down
function o:StepFontSize(delta)
	local sizes = fut:GetFontSizes()
	local index = 1
	for i, size in ipairs(sizes) do
		if size == self.fontSize then index = i break end
	end
	local newIndex = Clamp(index + delta, 1, #sizes)
	if newIndex == index then return end
	self:SetFontSize(sizes[newIndex], true)
end

--- Toggles wrap mode. In no-wrap mode the EditBox is oversized (4000px) so
--- lines never wrap; in wrap mode it is pinned to the viewport width so the
--- text engine wraps at the visible edge.
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
	if notify then
		self:FireConfigChanged()
	end
end

--- @return LDK_CodeEditorOptions Current settings, regardless of what (if anything) just changed
function o:GetOptions()
	return {
		fontFamily = self.fontFamily,
		fontSize = self.fontSize,
		wrapText = self.wrapText,
	}
end

--- Registers the callback fired after any user-driven config change (font
--- dropdown pick, wrap checkbox click). Called with a full snapshot of
--- current options every time, not just the changed field -- callers that
--- want to persist can just do `DB.profile.codeEditor = options` with no
--- merge logic of their own.
--- @param callback fun(self: LDK_CodeEditorDialog, options: LDK_CodeEditorOptions)|nil
function o:SetOnConfigChanged(callback)
	self.onConfigChanged = callback
end

function o:FireConfigChanged()
	if self.onConfigChanged then
		self.onConfigChanged(self, self:GetOptions())
	end
end

--- Applies initial/programmatic settings, merged over current values (so a
--- partial table only touches the fields it names). Does not fire
--- OnConfigChanged -- the caller already knows what it just configured.
--- fontSize snaps to the nearest supported size (10/12/14/16/18/20/24/28).
--- @param options LDK_CodeEditorOptions|table|nil Partial table; omitted fields keep their current value
function o:Configure(options)
	options = options or {}
	-- Falls back to DEFAULTS.fontFamily if the requested key doesn't resolve to
	-- a real font choice -- e.g. persisted config referencing a family that was
	-- since removed. Without this, ApplyCodeFont's own nil-guard would silently
	-- no-op and leave whatever font was previously applied.
	local fontFamily = options.fontFamily or self.fontFamily or DEFAULTS.fontFamily
	if not fut:FindFontChoice(fontFamily) then
		fontFamily = DEFAULTS.fontFamily
	end
	self.fontFamily = fontFamily
	self.fontSize = fut:NearestFontSize(options.fontSize or self.fontSize or DEFAULTS.fontSize)
	local wrapText = options.wrapText
	if wrapText == nil then
		wrapText = self.wrapText
	end
	if wrapText == nil then
		wrapText = DEFAULTS.wrapText
	end

	self:ApplyCodeFont()
	self:SetWrapText(wrapText)
end

--- Rebuilds the gutter's "1..N" text and sizes both columns to the content.
function o:RefreshGutter()
	if not self.CodeEditBox then
		return
	end -- not constructed yet (see OnCodeEditBoxTextChanged)

	-- Reentrancy guard, for the synchronous path: SetText fires OnTextChanged
	-- inline, which lands back here. (Resizes are handled separately below --
	-- OnSizeChanged is dispatched asynchronously, so this flag is already back
	-- to false by the time it arrives and cannot catch that case.)
	if self.refreshingGutter then
		return
	end
	self.refreshingGutter = true

	local gutter = self.Gutter
	local child = gutter.ScrollChild
	local numbers = child.Numbers

	-- Every setter below is guarded by SizeDiffers. Re-applying an unchanged size
	-- still makes WoW re-fire OnSizeChanged and recompute the caret (firing
	-- OnCursorChanged), so an unguarded SetHeight here re-entered this function
	-- every frame forever -- the size never changed, but the events never stopped,
	-- and the constant caret recalculation kept the cursor from ever rendering.

	-- Size the gutter to the highest line number's digit count first: the code
	-- viewport is anchored to GutterBackdrop's right edge, so every width read
	-- below (including wrap mode's measuring width) depends on this one.
	local lastLine = CountLines(self)
	local backdropWidth = GutterWidth(self, lastLine)
	if SizeDiffers(self.GutterBackdrop:GetWidth(), backdropWidth) then
		self.GutterBackdrop:SetWidth(backdropWidth)
	end

	-- Width must be set explicitly (scroll children ignore right-side anchors).
	-- Sized to the numbers EditBox, not to the Gutter: the child is what the
	-- EditBox anchors to, so a gutter-width child clipped every number down to
	-- the gutter and a 4-digit line stopped rendering at "...". Wider than the
	-- Gutter is fine -- the Gutter clips the overhang, and the numbers are
	-- right-justified, so the digits still land at its right edge.
	local gutterWidth = gutter:GetWidth()
	if SizeDiffers(child:GetWidth(), gutterWidth) then
		child:SetWidth(gutterWidth)
	end

	if self.wrapText then
		-- Keep the EditBox and the measuring string wrapping at the same width;
		-- wrap points move with the viewport, so this must track resizes too.
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
	if self.wrapText then
		text, rows = WrappedLineNumbersText(self)
	else
		text, rows = LineNumbersText(lastLine)
	end

	-- Both columns render the same row count in the same font, so rows times the
	-- font's line height IS the code's content height. Taken from WrapMeasure's
	-- FontString (same font) because an EditBox has no GetStringHeight. Sizing
	-- both columns to it gives the two ScrollFrames an identical scroll range,
	-- keeping SetVerticalScroll in sync down to the last line.
	local lineHeight = self.WrapMeasure.Text:GetLineHeight()
	local contentHeight = math.max(rows * lineHeight, self.ScrollFrame:GetHeight())
	if SizeDiffers(child:GetHeight(), contentHeight) then
		child:SetHeight(contentHeight)
	end
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
	-- SetText leaves the caret at the end; reset it so the gutter EditBox has no
	-- reason to scroll its own text toward the caret and out of line with the code.
	numbers:SetCursorPosition(0)

	self.refreshingGutter = false
end

--- @return string
function o:GetText()
	return self.CodeEditBox:GetText()
end

--- Text past MAX_LINES is dropped: this is a scratchpad for prototyping code
--- in-game, not a file editor, and an unbounded EditBox is what made the
--- gutter truncate mid-number in the first place.
--- @param text string
function o:SetText(text)
	self.CodeEditBox:SetText(TrimToMaxLines(text or ""))
	self:RefreshGutter()
end
