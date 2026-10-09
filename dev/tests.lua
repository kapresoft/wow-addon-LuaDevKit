
-- cleanup via real db
local function cleanupDb()
  local realdb = LUADEVKIT_DB
  realdb['global'] = nil
  realdb['profileKeys'] = nil
  realdb['profiles'] = nil
end; cleanupDb()

local function t1()
  local db = LUADEVKIT_DB
  local g = db['global']
  local editor = g.editor
  print('db=', fmtx(db))
end; t1()

local function t2()
  local ns = LDK_CORE_NS
  local realdb = LUADEVKIT_DB
  local db = ns:db()
  local g = ns:g()
  local editor, p = g.editor, db.profile
  print('db=', fmtx(db))
  print('profile=', fmtx(p))
end

local function t3()
  local as = LibStub('AceSerializer-3.0')
  print('as=', as)
  local ser = as:Serialize(LUADEVKIT_DB)
  print('LUADEVKIT_DB=', ser)
end; t3()

local function t4()
  local ns = LDK_CORE_NS
  local db = ns:db()
  local g = ns:g()
  local editor, p = g.editor, db.profile
  print('profile=', fmtx(p))
end; t4()