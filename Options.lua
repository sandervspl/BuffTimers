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

    if BuffTimersOptions[key] == nil then
        BuffTimersOptions[key] = def
    end

    return BuffTimersOptions[key]
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
    b.text:SetTextColor(1, 1, 1)
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
        local b = createCheckbox(L["Show seconds"], "seconds", true)
        b:SetPoint("TOPLEFT", f, 15, nextpos())
    end

    do
        local s = CreateFrame("Slider", f, f, "OptionsSliderTemplate")
        s:SetOrientation('HORIZONTAL')
        s:SetHeight(14)
        s:SetWidth(160)
        s:SetMinMaxValues(1, 120)
        s:SetValueStep(1)
        s.Low:SetText(SecondsToTime(60))
        s.High:SetText(SecondsToTime(7200))

        local l = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        l:SetPoint("RIGHT", s, "LEFT", -20, 1)
        l:SetText(L["Show seconds below this time"])
        l:SetTextColor(1, 1, 1)
        
        s:SetPoint("TOPLEFT", f, 40 + l:GetStringWidth(), nextpos(45))

        local key = "seconds_threshold"

        s:SetScript("OnValueChanged", function(self, value)
            s.Text:SetText(SecondsToTime(value * 60))
            SetConfig(key, value)
        end)

        RegisterKeyChangedCallback(key, function(v)
            s:SetValue(v)
        end)
    
        triggerCallback(key, GetConfigOrDefault(key, 120))
    end

    do
        local b = createCheckbox(L["Show milliseconds below 5 seconds"], "milliseconds", true)
        b:SetPoint("TOPLEFT", f, 15, nextpos())
    end

    do
        local b = createCheckbox(L["Always yellow text color"], "yellow_text", false)
        b:SetPoint("TOPLEFT", f, 15, nextpos())
    end
end)
