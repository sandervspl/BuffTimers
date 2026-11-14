-- lua Tests/text-style-replay.lua
-- Failure cases: omitted anchor offsets, a stale/rejected relative region,
-- layout changes after capture, one bad duration blocking other restorations,
-- repeated aura ticks retrying a failed restore, and re-enabling customization.
-- Simulated SetPoint validation, not WoW security/taint emulation.
local Helpers = dofile("Tests/helpers.lua")
local function check(value, message)
    assert(value, message)
    print("PASS " .. message)
end

for _, client in ipairs(Helpers.supportedClients) do
    local env = Helpers.loadAddon({ modern = true, profile = {
        customize_text = true, font_size = 18, vertical_position = -45,
    } })
    local layout = { isHorizontal = true, addIconsToRight = false, addIconsToTop = false }
    local rejectedRegion = {}
    local rejectedCalls = 0
    local function auraWithAnchor(relativeTo, offsetX, offsetY)
        local aura = { Icon = {} }
        function aura:GetParent() return layout end
        local duration = Helpers.newDuration()
        aura.Duration = duration
        duration.points = { { "TOP", relativeTo or aura.Icon, "BOTTOM", offsetX, offsetY } }
        local original = duration.SetPoint
        function duration:SetPoint(point, target, relativePoint, x, y)
            assert(type(point) == "string" and type(relativePoint) == "string", "invalid anchor points")
            assert(type(x) == "number" and type(y) == "number", "missing anchor offsets")
            if target == rejectedRegion then
                rejectedCalls = rejectedCalls + 1
                error("FontString:SetPoint(): Usage: rejected relative region")
            end
            original(self, point, target, relativePoint, x, y)
        end
        env.addon.OnAuraDurationUpdate(aura, 6300)
        return aura
    end

    local valid = auraWithAnchor(nil, 2, -3)
    local omitted = auraWithAnchor(nil)
    local stale = auraWithAnchor(rejectedRegion, 0, 0)
    -- The layout changed while customization was active. Fallback must use the
    -- current native orientation rather than the old customized text position.
    layout.isHorizontal = false
    layout.addIconsToRight = true
    env.addon:SetTextCustomizationEnabled(false)
    check(valid.Duration.point[4] == 2 and valid.Duration.point[5] == -3,
        client.name .. ": valid saved anchors retain their offsets")
    check(omitted.Duration.point[4] == 0 and omitted.Duration.point[5] == 0,
        client.name .. ": omitted native anchor offsets restore as zero")
    check(stale.Duration.point[1] == "LEFT" and stale.Duration.point[2] == stale.Icon
        and stale.Duration.point[3] == "RIGHT",
        client.name .. ": rejected anchor falls back to current native layout")
    check(stale.Duration.font[2] == 10 and stale.Duration.drawLayer == "BACKGROUND",
        client.name .. ": bad anchor does not block native font and layer restoration")
    for _ = 1, 120 do
        for _, aura in ipairs({ valid, omitted, stale }) do
            env.addon.OnAuraDurationUpdate(aura, 6200)
        end
    end
    check(rejectedCalls == 1, client.name .. ": subsequent aura ticks never retry rejected anchor")
    env.addon:SetTextCustomizationEnabled(true)
    env.addon.OnAuraDurationUpdate(stale, 6100)
    check(stale.Duration.font[2] == 18 and stale.Duration.point[5] == -45,
        client.name .. ": customization can be enabled again")
    env.addon:SetTextCustomizationEnabled(false)
    check(stale.Duration.font[2] == 10 and rejectedCalls == 1,
        client.name .. ": a second disable restores the fresh native anchor")
end
print("PASS text-style restoration replay; real client confirmation still required")
