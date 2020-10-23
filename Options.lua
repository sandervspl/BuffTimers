local _, ADDONSELF = ...
local L = ADDONSELF.L
local RegEvent = ADDONSELF.regevent

RegEvent("ADDON_LOADED", function()
    if not BuffTimersOptions then
        BuffTimersOptions = {}
    end
end)

local defs = {}
local function GetConfigOrDefault(key, def)
    defs[key] = def

    local config = BuffTimersOptions

    if config[key] == nil then
        config[key] = def
    end

    return config[key]
end

local changedcb = {}
local function RegisterKeyChangedCallback(key, cb)
    if not changedcb[key] then
        changedcb[key] = {}
    end

    table.insert(changedcb[key] , cb)
end
ADDONSELF.RegisterKeyChangedCallback = RegisterKeyChangedCallback

local function triggerCallback(key, value)
    for _, cb in pairs(changedcb[key] or {}) do
        cb(value)
    end
end

local function SetConfig(key, value)
    BuffTimersOptions[key] = value

    triggerCallback(key, value)
end


local f = CreateFrame("Frame", nil, UIParent)
f.name = L["BuffTimers"]
InterfaceOptions_AddCategory(f)

do
    local t = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    t:SetText(L["BuffTimers"])
    t:SetPoint("TOPLEFT", f, 15, -15)
end

local function createCheckbox(title, key, def)
    local b = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("LEFT", b, "RIGHT", 0, 1)
    b.text:SetText(title)
    b:SetScript("OnClick", function()
        SetConfig(key, b:GetChecked())
    end)

    RegisterKeyChangedCallback(key, function(v)
        b:SetChecked(v)
    end)

    triggerCallback(key, GetConfigOrDefault(key, def))
    return b
end

RegEvent("PLAYER_LOGIN", function()
    f.default = function()
        for k, v in pairs(defs) do
            SetConfig(k, v)
        end
    end

    f.refresh = function()
    end

    local base = -15
    local nextpos = function(offset)
        if not offset then
            offset = 30
        end
        base = base - offset
        return base
    end

    do
        local b = createCheckbox(L["Show seconds in buff time"], "seconds", true)
        b:SetPoint("TOPLEFT", f, 15, nextpos())
    end
end)
