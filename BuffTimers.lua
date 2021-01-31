local function formatTime(time)
    local timeStamp = BuffTimersOptions["time_stamp"]
    local isSecondsOption = BuffTimersOptions["seconds"]
    local seconds = floor(time % 60)
    local minutes = floor(time / 60)
    local hours = floor(minutes / 60)
    local remainingMins = minutes % 60 -- This calculates minutes beyond 1 hour
    local milliseconds = 0

    if minutes == 0 and seconds < 5 then
        milliseconds = floor((time % 60) % 1 * 10)
    end

    if not isSecondsOption or minutes >= BuffTimersOptions["seconds_threshold"] then
        minutes = ceil(time / 60)
    else
        -- Prefix seconds with a zero
        if (minutes > 0 and seconds < 10) then
            seconds = 0 .. seconds
        end
    end

    local secondsStr = seconds .. "s"

    local tempSeconds = floor(time % 60)
    if minutes < 1 and tempSeconds < 5 and BuffTimersOptions["milliseconds"] then
        secondsStr = seconds .. "." .. milliseconds .. "s"
    end

    if isSecondsOption and minutes < BuffTimersOptions["seconds_threshold"] then
        if timeStamp == "hm" and hours >= 1 then
            return hours .. ":" .. remainingMins .. ":" .. seconds
        elseif minutes >= 1 then
            return minutes .. ":" .. seconds
        else
            return secondsStr
        end
    else
        if timeStamp == "hm" and hours >= 1 then
            return hours .. ":" .. remainingMins .. "h"
        elseif minutes > 1 then
            return minutes .. "m"
        else
            return secondsStr
        end
    end
end

local function onAuraDurationUpdate(aura, time)   
    local duration = getglobal(aura:GetName() .. "Duration")
    
    if (time) then
        duration:SetText(formatTime(time))

        if BuffTimersOptions["yellow_text"] then
            duration:SetTextColor(0.99999779462814, 0.81960606575012, 0)
        end

        duration:Show()
    else
        duration:Hide()
    end
end

local function onAuraUpdate(auraSlot, index, filter)
    local auraName = auraSlot .. index
    local aura = getglobal(auraName)
    local auraDuration = getglobal(auraName .. "Duration")
    
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
