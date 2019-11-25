SLASH_BUFFTIMERS1 = "/bufftimers"
SLASH_BUFFTIMERS2 = "/bt"

SlashCmdList["BUFFTIMERS"] = function(msg)
    msg = string.lower(msg)

    if msg == "seconds" then
        BuffTimersOptions["seconds"] = not BuffTimersOptions["seconds"]

        if (BuffTimersOptions["seconds"]) then
            print("BuffTimers: enabled buffs to display seconds.")
        else
            print("BuffTimers: disabled buffs to display seconds.")
        end
    end
end

local function formatTime(time)
    local minutes = ceil(time / 60)
    local seconds = floor(mod(time, 60))

    if minutes > 1 then
        if BuffTimersOptions["seconds"] then
            -- Prefix seconds with a zero
            if (seconds < 10) then
                seconds = 0 .. seconds
            end

            return minutes .. ":" .. seconds
        else
            return minutes .. "m"
        end
    else
        return seconds .. "s"
    end
end

local function onAuraDurationUpdate(aura, time)   
    local duration = getglobal(aura:GetName().."Duration")
    
    if (time) then
        duration:SetText(formatTime(time))
        duration:Show()
    else
        duration:Hide()
    end
end

local function onAuraUpdate(auraSlot, index, filter)
    local auraName = auraSlot..index
    local aura = getglobal(auraName)
    local auraDuration = getglobal(auraName.."Duration")
    
    if not auraDuration then
        return
    end

    local name, _, _, _, _, expirationTime = UnitAura("player", index, filter)
    
    if (name and expirationTime > 0) then
        auraDuration:Show()
    else
        auraDuration:Hide()
    end
end

-- Add or remove aura event
hooksecurefunc("AuraButton_Update", onAuraUpdate)

-- Aura duration update event
hooksecurefunc("AuraButton_UpdateDuration", onAuraDurationUpdate)

-- Addon load event
local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")

function frame:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == "BuffTimers" then
        if (not BuffTimersOptions) then
            BuffTimersOptions = {}
            BuffTimersOptions["seconds"] = false
        end
    end
end

frame:SetScript("OnEvent", frame.OnEvent)
