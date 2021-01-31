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

    local secondsStr = seconds
    local remainingMinsStr = remainingMins

    if not isSecondsOption or minutes >= BuffTimersOptions["seconds_threshold"] then
        minutes = ceil(time / 60)
    else
        -- Prefix seconds with a zero
        if minutes > 0 and seconds < 10 then
            secondsStr = 0 .. seconds
        end
    end

    -- Prefix mins with a zero
    if remainingMins > 0 and remainingMins < 10 then
        remainingMinsStr = 0 .. remainingMins
    end

    if minutes < 1 and seconds < 5 and BuffTimersOptions["milliseconds"] then
        secondsStr = seconds .. "." .. milliseconds
    end

    if isSecondsOption and minutes < BuffTimersOptions["seconds_threshold"] then
        if timeStamp == "hm" and hours >= 1 and remainingMins > 0 then
            return hours .. ":" .. remainingMinsStr .. ":" .. secondsStr
        elseif minutes >= 1 then
            return minutes .. ":" .. secondsStr
        else
            return secondsStr .. "s"
        end
    else
        if timeStamp == "hm" and hours >= 1 and remainingMins > 0 then
            return hours .. ":" .. remainingMinsStr .. "h"
        elseif minutes > 1 then
            return minutes .. "m"
        else
            return secondsStr .. "s"
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
