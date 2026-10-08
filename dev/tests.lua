
-- cleanup via real db
local function cleanupDb()
  local realdb = LUADEVKIT_DB
  realdb['global'] = {}
  realdb['profileKeys'] = {}
  realdb['profiles'] = {}
end

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