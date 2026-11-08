-- Failure cases: secret arithmetic, native white winning on every combat tick,
-- missing compact-text API, yellow losing priority to multicolor, and toggling
-- yellow off while the timer remains secret.
local Helpers = dofile("Tests/helpers.lua")
local secret = setmetatable({}, {
    __lt = function() error("secret comparison") end,
    __div = function() error("secret arithmetic") end,
    __tostring = function() error("secret conversion") end,
})
local env = Helpers.loadAddon({ issecretvalue = function(value) return value == secret end })
local duration = Helpers.newDuration()
function duration:GetText() return self.text end
local aura = { Duration = duration }
local yellow = { 0.99999779462814, 0.81960606575012, 0, 1 }
local function checkColor(expected)
    for i = 1, 4 do assert(duration.color[i] == expected[i], "wrong timer color") end
end
local function nativeTick(time)
    duration:SetTextColor(1, 1, 1, 1)
    duration:SetText("23 s")
    env.addon.OnAuraDurationUpdate(aura, time)
end
env.addon.db.profile.yellow_text = true
env.addon.db.profile.colored_text = true
C_StringUtil = nil
nativeTick(23)
checkColor(yellow)
for i = 1, 3 do
    nativeTick(secret)
    checkColor(yellow)
    assert(duration.text == "23 s")
end
C_StringUtil = { RemoveContiguousSpaces = function(text) return (text:gsub(" ", "")) end }
nativeTick(secret)
checkColor(yellow)
assert(duration.text == "23s")
env.addon.db.profile.yellow_text = false
nativeTick(secret)
checkColor({ 1, 1, 1, 1 })
nativeTick(23)
checkColor({ 1, 0.1, 0.1, 1 })
print("PASS: readable/secret timer transitions, repeated native ticks, option priority, missing API, combat exit")
