SLASH_BUFFTIMERS1 = "/bufftimers"
SLASH_BUFFTIMERS2 = "/bt"

local function commandMessage(msg, msg2)
    DEFAULT_CHAT_FRAME:AddMessage("|caaaaaaaa" .. msg .. "|r" .. " " .. msg2)
end

SlashCmdList["BUFFTIMERS"] = function(msg)
    msg = string.lower(msg)

    if msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("These are the commands available to the BuffTimers addon:")
        commandMessage("seconds", "Toggle to show/hide the seconds in the buff time")
    elseif msg == "seconds" then
        BuffTimersOptions["seconds"] = not BuffTimersOptions["seconds"]

        if (BuffTimersOptions["seconds"]) then
            DEFAULT_CHAT_FRAME:AddMessage("BuffTimers: enabled buffs to display seconds.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("BuffTimers: disabled buffs to display seconds.")
        end
    end
end

local function formatTime(time)
    local isSecondsOption = BuffTimersOptions["seconds"]
    local seconds = floor(mod(time, 60))
    local minutes = floor(time / 60)

    if not isSecondsOption then
        minutes = ceil(time / 60)
    else
        -- Prefix seconds with a zero
        if (minutes > 0 and seconds < 10) then
            seconds = 0 .. seconds
        end
    end

    if isSecondsOption then
        if minutes >= 1 then
            return minutes .. ":" .. seconds
        else
            return seconds .. "s"
        end
    else
        if minutes > 1 then
            return minutes .. "m"
        else
            return seconds .. "s"
        end
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
            BuffTimersOptions["seconds"] = true
        end
    end
end

frame:SetScript("OnEvent", frame.OnEvent)
