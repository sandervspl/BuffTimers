local function formatTime(time)
    local isSecondsOption = BuffTimersOptions["seconds"]
    local seconds = floor(mod(time, 60))
    local minutes = floor(time / 60)

    if not isSecondsOption or minutes >= BuffTimersOptions["seconds_threshold"] then
        minutes = ceil(time / 60)
    else
        -- Prefix seconds with a zero
        if (minutes > 0 and seconds < 10) then
            seconds = 0 .. seconds
        end
    end

    if isSecondsOption and minutes < BuffTimersOptions["seconds_threshold"] then
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
    local duration = getglobal(aura:GetName() .. "Duration")
    
    if (time) then
        duration:SetText(formatTime(time))
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
