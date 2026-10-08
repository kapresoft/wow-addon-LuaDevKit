--- @type LDK_CodeEditor_Namespace
local ns = select(2, ...)

-- Sample text long enough to force scrolling, for testing gutter/scroll sync.
local ex1 = [==[
-- Example code
local args = ...

--- This is a fibonacci function
--- @return number @An emmylua comment
local function fibonacci(n)
  if n <= 1 then
    return n
  end
  return fibonacci(n - 1) + fibonacci(n - 2)
end

--[[ Sample long comment ]]
--- @param count number
local function printFibonacciSequence(count)
  for i = 1, count do
    print(i, fibonacci(i))
  end
end

-- Sample Logical Operators
local x,y = 1,2
if x and y or x == 1 and y == 2 then
  print('Yolo!')
end

local Frame = CreateFrame('Frame')
Frame:RegisterEvent('PLAYER_ENTERING_WORLD')
Frame:SetScript('OnEvent', function(self, event, ...)
  if event ~= 'PLAYER_ENTERING_WORLD' then return end
  printFibonacciSequence(10)
end)

local t = {}
for i = 1, 20 do
  t[i] = i * i
end

local function sum(tbl)
  local total = 0
  for _, v in ipairs(tbl) do
    total = total + v
  end
  return total
end

print('Sum of squares:', sum(t))

]==]
ex1 = ex1 .. "\n" .. ex1 .. "\n" .. ex1
ex1 = ex1
	.. "\n"
	.. ex1
	.. "\n"
	.. ex1
	.. "\n"
	.. ex1
	.. "\n"
	.. ex1
	.. "\n"
	.. ex1
	.. "\n"
	.. ex1
	.. "\n"
	.. ex1
	.. "\n"
	.. ex1
	.. "\n"
	.. ex1
	.. "\n"
	.. ex1
ex1 = ex1 .. "\n" .. ex1
ex1 = ex1 .. "\n" .. ex1

local ex2 = [==[
-- Example code
local function x()
  tmp = { 1, 2, 3, fn=function() print('hi') end }
  print('Spell=', fmtx(C_Spell))
  print('x=', fmt(x))
end
x()
]==]

local ex3 = [==[
--- Prints the failure in red, then raises it to stop the test run.
--- @param ok any
--- @param fmt string
local function _assert(ok, fmt, ...)
  if ok then return end
  local msg = fmt:format(...)
  print(RED_FONT_COLOR:WrapTextInColorCode(msg))
  error(msg, 2)
end

-- test 1: Load AddOn
local function t1()
  local name = 't1:Load AddOn'
  local addon = 'SharedMediaFontsMono'
  --- Loads SharedMediaFontsMono (LoadOnDemand); safe to call repeatedly.
  --- @return boolean @false if the client refused to load it
  local function LoadSharedMediaFontsMono()
    if C_AddOns.IsAddOnLoaded(addon) then return true end

    local loaded, reason = C_AddOns.LoadAddOn(addon)
    if not loaded then
      local why = _G['ADDON_' .. tostring(reason)] or tostring(reason)
      print(addon, 'failed to load:', why)
    end
    return loaded
  end

  local expectedLocale, expectedLoaded = 'enUS', true
  local expectedMonoType, expectedFile = 'font-mono', 'RobotoMono-Medium.ttf'
  local expectedDefault = 'JetBrains Mono'
  print(('Test[%s]: Start'):format(name))

  local localeOk = GetLocale() == expectedLocale
  _assert(
    localeOk,
    'Test[%s]: FAILED; locale: expected %s, got %s',
    name,
    expectedLocale,
    GetLocale()
  )

  local loaded = LoadSharedMediaFontsMono()
  local loadedOk = loaded == expectedLoaded
  _assert(
    loadedOk,
    'Test[%s]: FAILED; %s loaded: expected %s, got %s',
    name,
    addon,
    tostring(expectedLoaded),
    tostring(loaded)
  )

  -- Fonts are registered with LSM as soon as it loads
  local LSM = LibStub('LibSharedMedia-3.0')
  local FONT_MONO = LSM.MediaType.FONT_MONO
  local monoTypeOk = FONT_MONO == expectedMonoType
  _assert(
    monoTypeOk,
    'Test[%s]: FAILED; FONT_MONO: expected %s, got %s',
    name,
    expectedMonoType,
    tostring(FONT_MONO)
  )

  local fontN = 'Roboto Mono'
  -- noDefault: a missing font returns nil instead of the default
  local path = LSM:Fetch(FONT_MONO, fontN, true)
  print(addon, 'name=', fontN, 'path=', path)
  local pathOk = path ~= nil and path:find(expectedFile, 1, true) ~= nil
  _assert(
    pathOk,
    'Test[%s]: FAILED; "%s" path: expected %s, got %s',
    name,
    fontN,
    expectedFile,
    tostring(path)
  )

  local fontND = LSM:GetDefault(FONT_MONO)
  print(addon, 'default, name=', fontND, 'path=', LSM:Fetch(FONT_MONO, fontND))
  local defaultOk = fontND == expectedDefault
  _assert(
    defaultOk,
    'Test[%s]: FAILED; default: expected %s, got %s',
    name,
    expectedDefault,
    tostring(fontND)
  )

  local fontObjectOk = SharedMediaFontsMono_DefaultFont ~= nil
  _assert(fontObjectOk, 'Test[%s]: FAILED; SharedMediaFontsMono_DefaultFont is missing', name)

  local passed = localeOk and loadedOk and monoTypeOk and pathOk and defaultOk and fontObjectOk
  local result = passed and 'PASSED' or RED_FONT_COLOR:WrapTextInColorCode('FAILED')
  print(('Test[%s]: %s'):format(name, result))
end

-- test 2: List All Available Fonts
local function t2()
  local name = 't2:List All Available Fonts'
  local expectedLocale, expectedCount, expectedName = 'enUS', 7, 'Roboto Mono'
  print(('Test[%s]: Start'):format(name))

  local localeOk = GetLocale() == expectedLocale
  _assert(
    localeOk,
    'Test[%s]: FAILED; locale: expected %s, got %s',
    name,
    expectedLocale,
    GetLocale()
  )

  local LSM = LibStub('LibSharedMedia-3.0')
  local FONT_MONO = LSM.MediaType.FONT_MONO
  local fonts = LSM:List(FONT_MONO) or {}
  for i, fontName in ipairs(fonts) do
    print(i, fontName, LSM:Fetch(FONT_MONO, fontName))
  end

  local countOk = #fonts == expectedCount
  _assert(
    countOk,
    'Test[%s]: FAILED; font-mono count: expected %d, got %d',
    name,
    expectedCount,
    #fonts
  )

  local nameOk = LSM:IsValid(FONT_MONO, expectedName)
  _assert(nameOk, 'Test[%s]: FAILED; font-mono is missing "%s"', name, expectedName)

  local passed = localeOk and countOk and nameOk
  local result = passed and 'PASSED' or RED_FONT_COLOR:WrapTextInColorCode('FAILED')
  print(('Test[%s]: %s'):format(name, result), 'font-mono count=', #fonts)
end

-- test 3: List This Addon's 'font' Registrations
local function t3()
  local name = 't3:List Addon Fonts'
  local expectedLocale, expectedCount, expectedName = 'enUS', 7, 'RobotoMono Medium'
  print(('Test[%s]: Start'):format(name))

  local localeOk = GetLocale() == expectedLocale
  _assert(
    localeOk,
    'Test[%s]: FAILED; locale: expected %s, got %s',
    name,
    expectedLocale,
    GetLocale()
  )

  local LSM = LibStub('LibSharedMedia-3.0')
  local FONT = LSM.MediaType.FONT
  -- LSM registers its own built-in fonts too; count only ours
  local addonPath = [[Interface\AddOns\SharedMediaFontsMono\]]
  local paths = LSM:HashTable(FONT) or {}
  local count = 0
  for _, fontName in ipairs(LSM:List(FONT) or {}) do
    if paths[fontName]:find(addonPath, 1, true) then
      count = count + 1
      print(count, fontName, paths[fontName])
    end
  end

  local countOk = count == expectedCount
  _assert(countOk, 'Test[%s]: FAILED; font count: expected %d, got %d', name, expectedCount, count)

  local nameOk = LSM:IsValid(FONT, expectedName)
  _assert(nameOk, 'Test[%s]: FAILED; font is missing "%s"', name, expectedName)

  local passed = localeOk and countOk and nameOk
  local result = passed and 'PASSED' or RED_FONT_COLOR:WrapTextInColorCode('FAILED')
  print(('Test[%s]: %s'):format(name, result), 'font count=', count)
end

t1(); t2(); t3()

]==]

local ex4 = [==[
local function t1()
  local db = LUADEVKIT_DB
  local g = db['global']
  local editor = g.editor
  print('db=', fmtx(db))
end
local function t2()
  local ns = LDK_CORE_NS
  local realdb = LUADEVKIT_DB
  local db = ns:db()
  local g = ns:g()
  local editor, p = g.editor, db.profile
  print('db=', fmtx(db))
  print('profile=', fmtx(p))
end
--t1()
t2()
]==]

ns.EXAMPLE_CODE = ex4
