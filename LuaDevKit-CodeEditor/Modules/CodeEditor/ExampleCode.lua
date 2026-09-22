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
function()
  print('hello')
  return { 1, 2, 3}
end
]==]

ns.EXAMPLE_CODE = ex2
