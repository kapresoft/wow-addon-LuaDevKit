--[[-----------------------------------------------------------------------------
CommandBarMixin: CodeEditorDialog's single-line quick-eval input, mirroring
WowLua's own prompt (third-party/wowlua/WowLua.lua); sits on BottomBar,
below the output panel. Single-shot eval; no multi-line continuation.

CommandBar.CommandEditBox: plain EditBox, not LDK_CodeEditBoxMixin, wired
straight to OnEnterPressed. No native history (no historyLines):
commandHistory is the only list, stepped by StepCommandHistory. It's the
bar's height and centered on Prompt, so its text lines up with the prompt
at any font size.

CommandBar.Prompt: fixed LDK_CommandPromptFont, not the code font, so the
arrow keeps one shape; ApplyCodeFont leaves it alone. Anchored per theme in
the dialog's ApplyConsoleInsets.

CommandBar.HistoryButton: arrow dropdown listing that history, set up in
OnLoad_HistoryButton; right-aligned with the console settings gear in the
dialog's ApplyConsoleInsets.

CommandBar.HelpButton: tooltip lists the editor's built-in helpers and a
click prints them to the output; sits left of HistoryButton, and
CommandEditBox ends at its left edge.
-------------------------------------------------------------------------------]]
--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)
local CO = ns:cO()
local Themes, fut, FAIAP, LR = CO.Themes, CO.FontUtil, CO.FAIAP, CO.LuaRunner
local str_isBlank = CO.String.IsBlank
local AddTooltip = ns.O.DialogSupport.AddTooltip
local L = ns:GetLocale()
local HelpTour = ns.O.HelpTour
local upk = unpack
local libName = 'CommandBarMixin'

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local CreateFrame = CreateFrame

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
-- Arrow dropdown glyph; sized by the atlas, not the button.
local DROPDOWN_ARROW_SIZE = 18

-- Commands kept for Up/Down and the history menu.
local MAX_COMMAND_HISTORY = 50

-- History menu height before it scrolls.
local HISTORY_MENU_MAX_HEIGHT = 150

-- History row text width cap; WoW truncates longer lines.
local HISTORY_MENU_MAX_WIDTH = 200

-- Truncated-command tooltip width; long commands wrap at it.
local HISTORY_TOOLTIP_WIDTH = 400

-- Helpers tooltip's code face, independent of the editor's pick.
local MONO_FONT = { family = 'JetBrainsMono', size = 12 }

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- @class LDK_CommandHistoryEntry
--- @field text string
--- @field failed boolean? @Last run hit a compile or runtime error

--- @class LDK_CodeEditorCommandBarMixin : Frame, BackdropTemplate
--- @field owner LDK_CodeEditorDialog
--- @field HistoryTooltip GameTooltip               @History menu's own tooltip; shows truncated commands
--- @field HelpTooltip GameTooltip                  @HelpButton's own tooltip; its mono lines never leak to GameTooltip
--- @field commandHistory LDK_CommandHistoryEntry[] @Alias of global.console.history
--- @field historyIndex number                      @Up/Down position; one past the end is the draft
--- @field historyDraft string?                     @Unsent text saved when stepping into history
LDK_CodeEditorCommandBarMixin = {}
local o = LDK_CodeEditorCommandBarMixin

--- @class LDK_CodeEditorCommandBar : LDK_CodeEditorCommandBarMixin
--- @field Prompt FontString
--- @field CommandEditBox EditBox @Single-line quick-eval input with Up/Down history
--- @field HistoryButton DropdownButton
--- @field HelpButton Button

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- A CJK client has no JetBrains Mono; fall back to its default face.
--- @return Font
local function MonoFont()
  local choice = fut:FindFontChoice(MONO_FONT.family) or fut:GetDefaultFontChoice()
  return choice.bySize[MONO_FONT.size]
end

--- Sets the newest line's left text in font, keeping its color.
--- @param tooltip GameTooltip
--- @param font Font
--- @param color ColorMixin
local function SetLastLineFont(tooltip, font, color)
  local text = _G[tooltip:GetName() .. 'TextLeft' .. tooltip:NumLines()]
  text:SetFontObject(font)
  -- SetFontObject resets the color to the font's white.
  text:SetTextColor(color:GetRGB())
end

--- Signatures in the mono face; descriptions keep the tooltip font.
--- @param tooltip GameTooltip
--- @param font Font
--- @param helpers string[][]
local function AddHelperLines(tooltip, font, helpers)
  for _, helper in ipairs(helpers) do
    local signature, key = upk(helper)
    GameTooltip_AddColoredDoubleLine(
      tooltip,
      signature,
      L[key],
      HIGHLIGHT_FONT_COLOR,
      NORMAL_FONT_COLOR
    )
    SetLastLineFont(tooltip, font, HIGHLIGHT_FONT_COLOR)
  end
end

--- Code in white, output in gray, both unwrapped.
--- @param tooltip GameTooltip
--- @param font Font
--- @param example string[]
local function AddExampleLines(tooltip, font, example)
  for _, line in ipairs(example) do
    local color = line:find('^%-%-') and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR
    GameTooltip_AddColoredLine(tooltip, line, color, false)
    SetLastLineFont(tooltip, font, color)
  end
end

--- @param tooltip GameTooltip
--- @param owner Frame
local function ShowHelpersTooltip(tooltip, owner)
  GameTooltip_SetDefaultAnchor(tooltip, owner)
  GameTooltip_SetTitle(tooltip, L['Editor Helpers'])
  GameTooltip_AddNormalLine(tooltip, L['Editor Helpers::Desc'])
  GameTooltip_AddBlankLineToTooltip(tooltip)
  local font, helpers, example = MonoFont(), LR:GetHelpers()
  AddHelperLines(tooltip, font, helpers)
  GameTooltip_AddBlankLineToTooltip(tooltip)
  AddExampleLines(tooltip, font, example)
  GameTooltip_AddBlankLineToTooltip(tooltip)
  GameTooltip_AddInstructionLine(tooltip, L['Editor Helpers::Hint'])
  tooltip:Show()
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

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- Editable, unlike EvalStatus; native focus/keyboard.
--- Called from the dialog's Initialize, once the DB is ready.
--- @param owner LDK_CodeEditorDialog
function o:Initialize(owner)
  self.owner = owner
  self.Prompt:SetText('▶ ')
  self.CommandEditBox:SetAutoFocus(false)
  self.commandHistory = ns:g().console.history
  self.historyIndex = #self.commandHistory + 1
  self.CommandEditBox:SetScript('OnArrowPressed', function(_, key) self:StepCommandHistory(key) end)
  AddTooltip(self.CommandEditBox, 'Command Line')
  self:OnLoad_HistoryButton()
  self:OnLoad_HelpButton()
end

function o:OnLoad_HistoryButton()
  local button = self.HistoryButton
  PinArrowSize(button, DROPDOWN_ARROW_SIZE)
  -- The command bar sits low; open the menu upward.
  button:SetMenuAnchor(AnchorUtil.CreateAnchor('BOTTOMRIGHT', button, 'TOPRIGHT'))
  button:SetupMenu(function(_, root) self:BuildHistoryMenu(root) end)
  button:RegisterCallback(
    DropdownButtonMixin.Event.OnMenuOpen,
    function() HelpTour:CompleteStep('CommandHistory') end
  )
  AddTooltip(button, 'Command History')
  -- Own tooltip: its width and font never leak to GameTooltip.
  self.HistoryTooltip = CreateFrame(
    'GameTooltip',
    'LDK_CommandHistoryTooltip',
    UIParent,
    'SharedNoHeaderTooltipTemplate' --[[@as Template]]
  )
end

function o:OnLoad_HelpButton()
  local button = self.HelpButton
  local tooltip = CreateFrame(
    'GameTooltip',
    'LDK_EditorHelpersTooltip',
    UIParent,
    'SharedTooltipTemplate' --[[@as Template]]
  )
  self.HelpTooltip = tooltip
  button:HookScript('OnEnter', function() ShowHelpersTooltip(tooltip, button) end)
  button:HookScript('OnLeave', function() tooltip:Hide() end)
  button:SetScript('OnClick', function() self.owner:AppendOutput(LR:GetHelpText()) end)
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
      function(frame) ShowTruncatedCommand(frame, row, self:SyntaxColor(plain), self.owner.codeFont) end
    )
  end
end

--- Default syntax colors: the tooltip is dark in every theme.
--- @param text string @Escaped, as FAIAP sees editor text
--- @return string     @Plain if FAIAP isn't loaded
function o:SyntaxColor(text)
  local colors = ns:LuaColorTable(Themes:GetDefaultSyntax())
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

--- Runs one line from the command bar and appends every outcome -- the echoed
--- input, a compile error, a runtime error, or printed output -- to the same
--- output panel a full Run uses.
--- @param text string
function o:OnEnterPressed(text)
  if str_isBlank(text) then return end
  HelpTour:CompleteStep('CommandLine')

  local owner = self.owner
  -- Escape literal '|' so the echoed input can't be read as a color/texture code.
  owner:EchoCommand((text:gsub('|', '||')))

  local ok = LR:EvalCommand(text, function(line, kind) owner:AppendOutput(line, kind) end)
  self:PushCommandHistory(text, not ok)
end
