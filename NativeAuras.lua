-- Retail/Forever opt-out native buff renderer. The other clients keep the existing
-- hooks. Do not read aura identities/times or enumerate native frames in combat.
local _, _, _, interface = GetBuildInfo()
if interface ~= 16001 and interface ~= 120105 then return end

local BuffTimers = LibStub("AceAddon-3.0"):GetAddon("BuffTimers")
local Native = BuffTimers:NewModule("NativeAuras")
local root, hoverRoot, current, applied, active, timer
local available = false
local buttons = {}
local suppressingAlpha = false

-- Failure cases: unsupported profiles silently losing features; private/debuff
-- anchors being hidden; incorrect growth/stride/scale; stale cached durations;
-- restricted frame access in combat; profile changes during combat; and errors
-- leaving invisible original buttons after setup. Native mode is explicit and
-- rolls back to the existing renderer when its supported configuration changes.
local function Message(text)
    print("BuffTimers: " .. text)
end

local function SetOriginalsVisible(visible)
    for _, button in ipairs(BuffFrame.auraFrames) do
        if not button.isAuraAnchor then
            button:SetAlpha(visible and 1 or 0)
            button:EnableMouse(visible)
        end
    end
end

local function ResizeHost(capacity)
    -- BuffFrame's fixed-capacity sizing, including space for all three native
    -- enchant slots. Never derive host dimensions from a secret visible count.
    local layout = BuffFrame.AuraContainer
    local horizontal, stride = layout.isHorizontal, layout.iconStride or 1
    local width, height = horizontal and 30 or 60, horizontal and 40 or 30
    local lines, padding = math.ceil(capacity / stride), layout.iconPadding or 0
    width = (width + padding) * (horizontal and stride or lines)
    height = (height + padding) * (horizontal and lines or stride)
    local collapse = BuffFrame.CollapseAndExpandButton
    if collapse then
        if horizontal then width = width + collapse:GetWidth()
        else height = height + collapse:GetHeight() end
    end
    local scale = layout.iconScale or 1
    BuffFrame:SetSize(width * scale, height * scale)
end

local function Restore()
    if root then
        root:SetEnabled(false)
        root:Hide()
    end
    if hoverRoot then
        hoverRoot:SetEnabled(false)
        hoverRoot:Hide()
    end
    local wasActive = active
    active = false
    if wasActive then
        SetOriginalsVisible(true)
        ResizeHost(BuffFrame.maxAuras)
    end
end

local function MakeFormatter(profile)
    local rounding = Enum.NumericRuleFormatRounding
    local hourMode = profile.time_stamp == "hm"
    local secondsBefore = profile.seconds and (profile.seconds_threshold or 30) * 60 or 0
    local thresholds, seen = {}, {}
    -- All branching here uses public profile settings and fixed breakpoints.
    -- The native formatter selects the actual rule from secret remaining time.
    for _, threshold in ipairs({ 0, 5, 60, 3600, secondsBefore, 86400 }) do
        if not seen[threshold] then
            thresholds[#thresholds + 1] = threshold
            seen[threshold] = true
        end
    end
    table.sort(thresholds)
    local rules = {}
    for _, threshold in ipairs(thresholds) do
        local rule = { threshold = threshold }
        if threshold >= 86400 then
            -- Preserve the existing day policy, based on completed hours.
            rule.step, rule.rounding = 3600, rounding.Down
            rule.format = "%dd"
            rule.components = { { div = 86400, step = 1, rounding = rounding.Up } }
        elseif threshold < 60 then
            local tenths = profile.milliseconds and threshold < 5
            rule.format = tenths and "%.1fs" or "%ds"
            rule.step, rule.rounding = tenths and 0.1 or 1, rounding.Down
        elseif threshold < secondsBefore then
            if hourMode and threshold >= 3600 then
                rule.format = "%d:%02d:%02d"
                rule.components = {
                    { div = 3600, step = 1, rounding = rounding.Down },
                    { div = 60, mod = 60, step = 1, rounding = rounding.Down },
                    { mod = 60, step = 1, rounding = rounding.Down },
                }
            else
                rule.format = "%d:%02d"
                rule.components = {
                    { div = 60, step = 1, rounding = rounding.Down },
                    { mod = 60, step = 1, rounding = rounding.Down },
                }
            end
        elseif hourMode and threshold >= 3600 then
            -- Round the whole input before splitting hours/minutes so :60 can
            -- never appear when the rounded minute carries into the next hour.
            rule.step, rule.rounding = 60, rounding.Up
            rule.format = "%d:%02dh"
            rule.components = {
                { div = 3600, step = 1, rounding = rounding.Down },
                { div = 60, mod = 60, step = 1, rounding = rounding.Down },
            }
        else
            rule.format = "%dm"
            rule.components = { { div = 60, step = 1, rounding = rounding.Up } }
        end
        rules[#rules + 1] = rule
    end
    local f = C_StringUtil.CreateNumericRuleFormatter()
    f:SetBreakpoints(rules)
    -- Exercise the real native formatter with public values before adopting it.
    local showSeconds = 6300 < secondsBefore
    local expected = showSeconds and (hourMode and "1:45:00" or "105:00") or (hourMode and "1:45h" or "105m")
    local nextExpected = showSeconds and (hourMode and "1:45:01" or "105:01") or (hourMode and "1:46h" or "106m")
    assert(f:FormatNumber(6300) == expected and f:FormatNumber(6301) == nextExpected,
        "native timer formatter failed its checks")
    return f
end

local function MakeColorCurve(profile)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Step)
    local yellow = CreateColor(0.99999779462814, 0.81960606575012, 0, 1)
    if profile.yellow_text then
        curve:AddPoint(0, yellow)
    elseif profile.colored_text then
        curve:AddPoint(0, CreateColor(1, 0.1, 0.1, 1))
        curve:AddPoint(60, yellow)
        curve:AddPoint(600, CreateColor(0.1, 1, 0.1, 1))
    else
        curve:AddPoint(0, CreateColor(1, 1, 1, 1))
        curve:AddPoint(60, yellow)
    end
    return curve
end

local function MakeHoverFormatter()
    local down = Enum.NumericRuleFormatRounding.Down
    local f = C_StringUtil.CreateNumericRuleFormatter()
    f:SetBreakpoints({
        -- Empty text also gives the highlight backplate zero width below a minute.
        { threshold = 0, format = "" },
        { threshold = 60, format = "%02d:%02d", components = {
            { div = 60, step = 1, rounding = down },
            { mod = 60, step = 1, rounding = down },
        } },
        { threshold = 3600, format = "%02d:%02d:%02d", components = {
            { div = 3600, step = 1, rounding = down },
            { div = 60, mod = 60, step = 1, rounding = down },
            { mod = 60, step = 1, rounding = down },
        } },
    })
    assert(f:FormatNumber(59) == "" and f:FormatNumber(60) == "01:00"
        and f:FormatNumber(6300) == "01:45:00", "native detailed hover formatter failed its checks")
    return f
end

local function Configure(entry)
    local config, button, icon, text = current, entry.button, entry.icon, entry.text
    button:SetSize(config.width, config.height)
    icon:ClearAllPoints()
    icon:SetPoint(config.iconPoint, button, config.iconPoint)
    text:ClearAllPoints()
    if config.profile.customize_text then
        local profile = config.profile
        local outline = profile.font_outline
        if outline == "THICK" then outline = "THICKOUTLINE" end
        text:SetFont(BuffTimersLibSharedMedia:Fetch("font", profile.font), profile.font_size,
            outline ~= "" and outline or nil)
        text:SetPoint("BOTTOM", button, "TOP", 0, profile.vertical_position)
    else
        text:SetFontObject(GameFontNormalSmall)
        text:SetPoint(config.durationPoint, icon, config.durationRelativePoint)
    end
    if config.showDurations and (not entry.hover or config.profile.detailed_time_on_hover) then
        text:Show()
        button:SetDurationText(text, {
            textFormatter = entry.hover and config.hoverFormatter or config.formatter,
            textColor = { curve = config.color, property = Enum.DurationTextBindingProperty.RemainingDuration },
        })
    else
        button:ClearDurationText()
        text:Hide()
    end
end

local function InitializeButton(button, enchant, hover)
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(30, 30)
    if not hover then
        button:SetIcon(icon)
        local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
        button:SetApplicationCount(count)
    end
    local layer = hover and "HIGHLIGHT" or "OVERLAY"
    local text = button:CreateFontString(nil, layer, "GameFontNormalSmall")
    text:SetDrawLayer(layer, 1)
    if hover then
        -- The engine toggles HIGHLIGHT on mouseover. No addon OnEnter/OnLeave,
        -- focus queries, secret arithmetic, or combat-time reconfiguration.
        -- A matching native container owns the overlay's aura assignments.
        local backplate = button:CreateTexture(nil, "HIGHLIGHT")
        backplate:SetColorTexture(0, 0, 0, 1)
        backplate:SetAllPoints(text)
    elseif enchant then
        local border = button:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-TempEnchant-Border")
        border:SetSize(32, 32)
        border:SetPoint("CENTER", icon, "CENTER")
    end
    -- Native aura buttons propagate input. Only the main renderer cancels auras,
    -- so the overlay cannot turn one right-click into two cancellation attempts.
    button:SetCancelAuraButtons(not hover and "RightButtonUp" or nil)
    local entry = { button = button, icon = icon, text = text, hover = hover }
    buttons[#buttons + 1] = entry
    Configure(entry)
end

local function CreateNativeContainer(hover)
    local container = CreateFrame("AuraContainer", nil, BuffFrame, "CustomAuraContainerTemplate")
    container:SetEnabled(false)
    container:SetEditModePreviewEnabled(false)
    container:SetUnit("player")
    container:AddAuraGroup("buffs", "HELPFUL", {
        maxFrameCount = BuffFrame.maxAuras,
        sortMethod = AuraContainerSortMethod.AuraInstanceIDOnly,
        initializeFrame = function(button) InitializeButton(button, false, hover) end,
    })
    for _, slot in ipairs({ AuraContainerItemEnchantmentSlot.MainHand, AuraContainerItemEnchantmentSlot.OffHand,
        AuraContainerItemEnchantmentSlot.Ranged }) do
        container:AddItemEnchantment(slot, { initializeFrame = function(button) InitializeButton(button, true, hover) end })
    end
    return container
end

local function ConfigureContainer(container, layout)
    local horizontal, right, top = layout.isHorizontal, layout.addIconsToRight, layout.addIconsToTop
    local anchor = (top and "BOTTOM" or "TOP") .. (right and "LEFT" or "RIGHT")
    container:ClearAllPoints()
    container:SetPoint(anchor, layout, anchor)
    container:SetScale(layout.iconScale or 1)
    container:SetFlowLayoutAnchorPoint(anchor)
    container:SetFlowLayoutAxis(horizontal and AnchorUtil.FlowLayoutAxis.Horizontal or AnchorUtil.FlowLayoutAxis.Vertical)
    container:SetFlowLayoutGrowthDirection(right and AnchorUtil.FlowDirection.Right or AnchorUtil.FlowDirection.Left,
        top and AnchorUtil.FlowDirection.Up or AnchorUtil.FlowDirection.Down)
    local padding = layout.iconPadding or 0
    container:SetAuraGroupLayout("buffs", { elementSpacing = padding, lineSpacing = padding,
        elementWidth = current.width, elementHeight = current.height })
    container:SetItemEnchantmentLayout({ elementSpacing = padding, lineSpacing = padding, groupSpacing = padding,
        elementWidth = current.width, elementHeight = current.height })
    container:SetFlowLayoutMaximumLineSize((layout.iconStride or 1) *
        ((horizontal and current.width or current.height) + padding) - padding)
end

local function UnsupportedReason()
    if InputUtil.IsGamepadUIEnabled() then
        return "Native mode does not support gamepad navigation. Using the existing renderer."
    end
    if not BuffFrame:IsExpanded() then
        return "Expand your buffs to use native mode. Using the existing renderer while buffs are collapsed."
    end
end

local function Refresh()
    -- Configuration touches native button objects. Their engine-driven updates
    -- continue in combat; addon configuration waits until combat ends.
    if InCombatLockdown() then return end
    if not BuffTimersNativeDB.enabled then Restore(); return end
    local profile, layout = BuffTimers.db.profile, BuffFrame.AuraContainer
    local reason = UnsupportedReason()
    if reason then
        Restore()
        if applied ~= reason then Message(reason) end
        applied = reason
        return
    end
    if BuffFrame:IsEditing() then Restore(); applied = nil; return end

    local parts = {}
    for _, key in ipairs({ "time_stamp", "seconds", "seconds_threshold", "milliseconds", "yellow_text", "colored_text", "customize_text", "detailed_time_on_hover",
        "font", "font_size", "font_outline", "vertical_position" }) do
        parts[#parts + 1] = tostring(profile[key])
    end
    for _, key in ipairs({ "isHorizontal", "addIconsToRight", "addIconsToTop", "iconStride", "iconPadding", "iconScale" }) do
        parts[#parts + 1] = tostring(layout[key])
    end
    local showDurations = CVarCallbackRegistry:GetCVarValueBool("buffDurations")
    parts[#parts + 1] = tostring(showDurations)
    local signature = table.concat(parts, ":")
    if active and applied == signature then return end

    local horizontal, right, top = layout.isHorizontal, layout.addIconsToRight, layout.addIconsToTop
    current = {
        profile = CopyTable(profile),
        formatter = MakeFormatter(profile), color = MakeColorCurve(profile),
        hoverFormatter = profile.detailed_time_on_hover and MakeHoverFormatter() or nil,
        showDurations = showDurations,
        width = horizontal and 30 or 60, height = horizontal and 40 or 30,
        iconPoint = horizontal and (top and "BOTTOM" or "TOP") or (right and "LEFT" or "RIGHT"),
        durationPoint = horizontal and (top and "BOTTOM" or "TOP") or (right and "LEFT" or "RIGHT"),
        durationRelativePoint = horizontal and (top and "TOP" or "BOTTOM") or (right and "RIGHT" or "LEFT"),
    }
    if not root then root = CreateNativeContainer(false) end
    if profile.detailed_time_on_hover and not hoverRoot then hoverRoot = CreateNativeContainer(true) end
    -- Never index frames by aura order or transplant adopted FontStrings.
    for _, entry in ipairs(buttons) do Configure(entry) end
    ConfigureContainer(root, layout)
    if hoverRoot then
        ConfigureContainer(hoverRoot, layout)
        hoverRoot:SetFrameLevel(root:GetFrameLevel() + 1)
        local showHover = profile.detailed_time_on_hover and showDurations
        hoverRoot:SetEnabled(showHover)
        hoverRoot:SetShown(showHover)
    end
    root:Show()
    root:SetEnabled(true)
    active = true
    SetOriginalsVisible(false)
    ResizeHost(BuffFrame.maxAuras + 3)
    applied = signature
end

local function SafeRefresh()
    local ok, reason = pcall(Refresh)
    if not ok then
        Restore()
        BuffTimersNativeDB.enabled = false
        Message("Native mode stopped: " .. tostring(reason))
    end
end

function Native:GetNativeEnabled()
    return not BuffTimersNativeDB or BuffTimersNativeDB.enabled ~= false
end

function Native:IsNativeAvailable()
    return available
end

function Native:IsNativeActive()
    return active == true
end

function Native:SetNativeEnabled(enabled)
    if InCombatLockdown() or not available then return false end
    BuffTimersNativeDB.enabled = enabled == true
    SafeRefresh()
    return true
end

function Native:GetStatus()
    if not self:GetNativeEnabled() then return "Native buff timers are disabled." end
    if not available then return "Native aura APIs are unavailable on this client. Using the existing renderer." end
    local reason = UnsupportedReason()
    if reason then return reason end
    if BuffFrame:IsEditing() then return "Native buff timers are paused during Edit Mode." end
    if active then return "Native buff timers are active." end
    return "Native buff timers will resume after combat."
end

function Native:OnEnable()
    BuffTimersNativeDB = BuffTimersNativeDB or {}
    if BuffTimersNativeDB.enabled == nil then BuffTimersNativeDB.enabled = true end
    if not (BuffFrame and BuffFrame.AuraContainer and BuffFrame.auraFrames and BuffFrame.UpdateSize
        and BuffFrame.IsExpanded and BuffFrame.IsEditing and C_StringUtil and C_StringUtil.CreateNumericRuleFormatter
        and C_CurveUtil and C_CurveUtil.CreateColorCurve and AuraContainerSortMethod and AuraContainerItemEnchantmentSlot
        and Enum and Enum.NumericRuleFormatRounding and Enum.DurationTextBindingProperty and Enum.LuaCurveType
        and AnchorUtil and AnchorUtil.FlowLayoutAxis and AnchorUtil.FlowDirection
        and CVarCallbackRegistry and CVarCallbackRegistry.GetCVarValueBool
        and InputUtil and InputUtil.IsGamepadUIEnabled and C_Timer and C_Timer.NewTicker) then
        if BuffTimersNativeDB.enabled then Message(self:GetStatus()) end
        return
    end
    available = true
    hooksecurefunc(BuffFrame, "UpdateSize", function()
        if active then ResizeHost(BuffFrame.maxAuras + 3) end
    end)
    -- The legacy OnUpdate reapplies warning-flash alpha every tick. Keep those
    -- original buttons suppressed without inspecting its potentially secret alpha.
    for _, button in ipairs(BuffFrame.auraFrames) do
        if not button.isAuraAnchor then
            hooksecurefunc(button, "SetAlpha", function(original)
                if active and not suppressingAlpha then
                    suppressingAlpha = true
                    original:SetAlpha(0)
                    suppressingAlpha = false
                end
            end)
        end
    end
    timer = C_Timer.NewTicker(0.25, SafeRefresh)
    SafeRefresh()
end

function Native:OnDisable()
    if timer then timer:Cancel(); timer = nil end
    if not InCombatLockdown() then Restore() end
end
