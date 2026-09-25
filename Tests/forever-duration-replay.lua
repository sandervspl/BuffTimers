-- Run from the repo root after scripts/sync-wow-ui-source.sh forever:
-- lua Tests/forever-duration-replay.lua
-- This replays upstream Lua; it cannot emulate WoW combat protection or taint.
-- Failure cases: native text winning after a tick, locale styling winning last,
-- disabled durations being shown, stale text after removal/reuse, wrong timeMod,
-- edit previews being overwritten, and arithmetic on secret timer values.
local Helpers = dofile("Tests/helpers.lua")
local showDurations = true
CVarCallbackRegistry = {
    SetCVarCachable = function() end,
    GetCVarValueBool = function() return showDurations end,
}
HelpTip = { ButtonStyle = {}, Point = {}, Alignment = {} }
Enum = { FrameTutorialAccount = {} }
function CreateFromMixins(...)
    local result = {}
    for _, mixin in ipairs({...}) do
        for key, value in pairs(mixin) do result[key] = value end
    end
    return result
end
dofile(".cache/wow-ui-source/Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua")

PlayerFrame = { unit = "player" }
GameTooltip = { IsOwned = function() return false end }
BUFF_DURATION_WARNING_TIME = 60
HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }
NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
DEFAULT_AURA_DURATION_FONT = "GameFontNormalSmall"
SMALLER_AURA_DURATION_FONT = "GameFontHighlightSmall2"
SMALLER_AURA_DURATION_OFFSET_Y = -2
function securecall(callback, ...) return callback(...) end
function SecondsToTimeAbbrev(time)
    return "%d m", math.ceil(time / 60)
end

local function newButton(auraType)
    local button = CreateFromMixins(AuraButtonMixin)
    button.auraType = auraType
    button.Duration = Helpers.newDuration()
    function button.Duration:IsShown() return self.visible == true end
    function button.Duration:SetShown(shown) self.visible = not not shown end
    function button.Duration:SetFormattedText(format, ...)
        self:SetText(string.format(format, ...))
    end
    button.Duration.SetVertexColor = button.Duration.SetTextColor
    function button:GetParent() return nil end
    function button:SetAlpha() end
    function button:Hide() self.hidden = true end
    function button:SetScript(name, callback) self[name .. "Script"] = callback end
    -- XML captures this function before the addon is enabled.
    button:SetScript("OnUpdate", button.OnUpdate)
    return button
end

local buff, enchant, debuff = newButton("Buff"), newButton("TempEnchant"), newButton("Debuff")
local secret = {}
local env = Helpers.loadAddon({
    modernFrames = { buffs = { buff, enchant }, debuffs = { debuff } },
    smallerAuraDurationFont = true,
    issecretvalue = function(value) return value == secret end,
    profile = { customize_text = true, font_size = 18, vertical_position = -45 },
})
-- Execute both kinds of hooks so this harness also exercises the old implementation.
function hooksecurefunc(object, name, callback)
    local original = object[name]
    object[name] = function(...)
        original(...)
        callback(...)
    end
end
for _, button in ipairs({ buff, enchant, debuff }) do
    function button:HookScript(name, callback) self[name .. "Hook"] = callback end
end
env.addon:OnEnable()
local function update(button, expiration, timeMod)
    button.buttonInfo = { expirationTime = expiration, timeMod = timeMod, ID = 16 }
    button:UpdateExpirationTime(button.buttonInfo)
end
local function tick(button, now)
    env.now = now
    if button.OnUpdateScript then
        button.OnUpdateScript(button, 0.016)
        if button.OnUpdateHook then button.OnUpdateHook(button, 0.016) end
    end
end
local function check(condition, message)
    assert(condition, message)
    print("PASS " .. message)
end

update(buff, 3700)
update(enchant, 1900)
update(debuff, 220, 2)
-- Duration updates must work independently of the frame's OnUpdate script.
buff:UpdateDuration(1800)
check(buff.Duration.text == "30m", "direct duration update applies formatting without a frame tick")
tick(buff, 100)
check(buff.Duration.text == "60m", "long buff uses custom text")
check(buff.Duration.font[2] == 18, "custom font survives the registered locale update")
tick(buff, 1900)
tick(enchant, 100)
check(buff.Duration.text == "30m" and enchant.Duration.text == "30m", "buff and weapon enchant at 30 minutes")
tick(buff, 1961)
tick(enchant, 161)
check(buff.Duration.text == "29m" and enchant.Duration.text == "29m", "both timers cross the minute boundary")
tick(buff, 2021)
check(buff.Duration.text == "28m", "subsequent ticks retain custom formatting")
tick(debuff, 160)
check(debuff.Duration.text == "30s", "debuff respects timeMod")
showDurations = false
tick(buff, 2022)
check(not buff.Duration:IsShown(), "disabled durations stay hidden")
showDurations = true
update(buff, 0)
tick(buff, 2023)
check(not buff.Duration:IsShown(), "untimed reused button stays hidden")
update(buff, 2200)
tick(buff, 2080)
check(buff.Duration.text == "2m", "reused timed button resumes formatting")
buff.isExample = true
buff.Duration:SetText("preview")
tick(buff, 2081)
check(buff.Duration.text == "preview", "edit-mode example stays untouched")
buff.isExample = false
buff.timeLeft = secret
buff.Duration:SetText("native secret timer")
env.addon.OnAuraFrameUpdate(buff)
check(buff.Duration.text == "native secret timer", "secret timer stays with Blizzard")
print("PASS upstream duration replay (combat/taint require in-game verification)")
