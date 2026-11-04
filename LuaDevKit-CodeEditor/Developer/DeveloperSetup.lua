local addon, ns = ...
local function n() return ('{{%s}}'):format(BLUE_FONT_COLOR:WrapTextInColorCode(addon)) end
print(n(), 'DeveloperSetup loaded [dev]')
-- todo: implement: local p, t = ns:log('DeveloperSetup')
