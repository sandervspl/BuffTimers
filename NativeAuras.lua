-- Retail/Forever opt-out native buff renderer. The other clients keep the existing
-- hooks. Do not read aura identities/times or enumerate native frames in combat.
local _, _, _, interface = GetBuildInfo()
if interface ~= 16001 and interface ~= 120105 then return end

local BuffTimers = LibStub("AceAddon-3.0"):GetAddon("BuffTimers")
local Native = BuffTimers:NewModule("NativeAuras")
local root, hoverRoot, enchantHost, current, applied, active, timer, hoverDriver
local originalsHidden = false
local available = false
local buttons = {}
local enchantIcons = {}
local suppressingAlpha = false
local bbfEntries = setmetatable({}, { __mode = "k" })
local bbfActive, bbfBusy, bbfHooked = false, false, false
local RestoreBBF, RefreshBBF, SafeRefresh

local function BBFHost()
    local host = BBF and BBF.auraHosts and BBF.auraHosts.playerBuffs
    local container = host and host.buffs
    return host and host.frame == BuffFrame and container and container.bbfStyles
        and container.GetAuraGroupFrameCount and container.GetAuraGroupFrame and host or nil
end

-- Failure cases: unsupported profiles silently losing features; private/debuff
-- anchors being hidden; incorrect growth/stride/scale; stale cached durations;
-- restricted frame access in combat; profile changes during combat; and errors
-- leaving invisible original buttons after setup. Native mode is explicit and
-- rolls back to the existing renderer when its supported configuration changes.
local function Message(text)
    print("BuffTimers: " .. text)
end

local function CanAccess(object)
    local allowed = object:CanBeAccessedInContext()
    -- Security accessors may themselves return a secret. Never branch on it.
    return not (issecretvalue and issecretvalue(allowed)) and allowed
end

local function ConfigurationRestricted()
    return InCombatLockdown() or (C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret())
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
    -- Stop addon-driven work first, even if native cleanup must wait. Keep the
    -- separate originalsHidden flag until the original display is restored.
    active = false
    if ConfigurationRestricted() then return end
    if RestoreBBF then RestoreBBF() end
    if (root and not CanAccess(root)) or (hoverRoot and not CanAccess(hoverRoot))
        or (enchantHost and not CanAccess(enchantHost)) then return end
    if root then
        root:SetEnabled(false)
        root:Hide()
    end
    if hoverRoot then
        hoverRoot:SetEnabled(false)
        hoverRoot:Hide()
    end
    -- This parent has no anchors into native aura objects. Hiding it needs no
    -- calls on the individual enchant frames, which may have become forbidden.
    if enchantHost then enchantHost:Hide() end
    if originalsHidden then
        originalsHidden = false
        SetOriginalsVisible(true)
        if not BBFHost() then ResizeHost(BuffFrame.maxAuras) end
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

local function MakeColorCurve(profile, blinking)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Step)
    local yellow = { 0.99999779462814, 0.81960606575012, 0 }
    local short = profile.yellow_text and yellow or (profile.colored_text and { 1, 0.1, 0.1 } or { 1, 1, 1 })
    local function point(seconds, color, alpha)
        curve:AddPoint(seconds, CreateColor(color[1], color[2], color[3], alpha))
    end
    -- Keep the established step-based RGB policy. Sample only the warning alpha
    -- at 8 Hz using public constants; interpolation must not change text colors.
    -- 248 warning samples plus at most three boundaries fit the 256-point cap.
    -- The native binding still evaluates live remaining time, including refreshes.
    if blinking then
        for sample = 0, 247 do
            local seconds = sample / 8
            point(seconds, short, 0.65 + 0.35 * math.cos((31 - seconds) * math.pi / 0.75))
        end
    else
        point(0, short, 1)
    end
    point(31, short, 1)
    point(60, yellow, 1)
    if profile.colored_text and not profile.yellow_text then
        point(600, { 0.1, 1, 0.1 }, 1)
    end
    -- Validate the actual client implementation with public inputs, rather than
    -- relying only on the local curve simulation for color/alpha compatibility.
    -- The API does not promise double-precision color round-trips. Permit one
    -- 8-bit channel step, including alpha (0.3 is not exactly representable).
    local tolerance = 1 / 255 + 0.000001
    local function verify(seconds, expected, alpha)
        local r, g, b, a = curve:EvaluateUnpacked(seconds)
        assert(math.abs(r - expected[1]) <= tolerance and math.abs(g - expected[2]) <= tolerance
            and math.abs(b - expected[3]) <= tolerance and math.abs(a - alpha) <= tolerance,
            ("native timer color curve failed its checks at %.2fs (RGBA %.6f, %.6f, %.6f, %.6f)")
                :format(seconds, r, g, b, a))
    end
    verify(6300, profile.colored_text and not profile.yellow_text and { 0.1, 1, 0.1 } or yellow, 1)
    verify(31, short, 1)
    verify(30.25, short, blinking and 0.3 or 1)
    return curve
end

local function MakeHoverFormatter(profile)
    local down = Enum.NumericRuleFormatRounding.Down
    local f = C_StringUtil.CreateNumericRuleFormatter()
    f:SetBreakpoints({
        { threshold = 0, format = profile.milliseconds and "%.1fs" or "%ds",
            step = profile.milliseconds and 0.1 or 1, rounding = down },
        { threshold = 5, format = "%ds", step = 1, rounding = down },
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
    assert(f:FormatNumber(59) == "59s" and f:FormatNumber(60) == "01:00"
        and f:FormatNumber(6300) == "01:45:00", "native detailed hover formatter failed its checks")
    return f
end

-- BetterBlizzFrames owns native player aura containers on Retail and Forever.
-- Adapt their timer channels instead of creating another competing buff grid.
local function ConfigureBBFButton(button, style)
    if not button.bbfTimer or not style then return end
    local entry = bbfEntries[button]
    if entry and entry.config == current then return end
    if not entry then
        entry = { button = button, text = button.bbfTimer, art = {} }
        entry.compact = button.bbfTextLayer or button.bbfTimer:GetParent()
        -- BBF deliberately clears its ordinary imbue cooldown when swipes are
        -- disabled. Use a separate clock for that public duration binding.
        entry.duration = button.bbfDuration
        entry.binding = button.bbfBinding
        entry.cooldown = not entry.binding and button.bbfCooldown or nil
        if not entry.cooldown then
            entry.cooldown = CreateFrame("Cooldown", nil, button,
                "DisableUntrustedScriptsTemplate,DisableUntrustedLayoutScriptsTemplate")
            entry.cooldown:SetAllPoints(button.bbfIcon or button)
            entry.cooldown:SetDrawSwipe(false)
            entry.cooldown:SetDrawEdge(false)
            entry.cooldown:SetDrawBling(false)
            entry.ownsCooldown = true
        end
        entry.oldFormatter = entry.cooldown:GetCountdownFormatter()
        entry.oldHideNumbers = entry.cooldown:GetHideCountdownNumbers()
        entry.hoverText = entry.cooldown:GetCountdownFontString()
        entry.hit = CreateFrame("Frame", nil, BuffFrame, "DisableUntrustedLayoutScriptsTemplate")
        entry.hit:SetAllPoints(button)
        bbfEntries[button] = entry
    end
    entry.art = {}
    for _, key in ipairs({ "bbfIcon", "bbfEnchantIcon", "bbfCount", "bbfBorder" }) do
        if button[key] then entry.art[#entry.art + 1] = button[key] end
    end
    entry.managed, entry.style = true, style
    local profile, text, cooldown = current.profile, entry.text, entry.cooldown
    if profile.customize_text then
        local outline = profile.font_outline
        if outline == "THICK" then outline = "THICKOUTLINE" end
        text:SetFont(BuffTimersLibSharedMedia:Fetch("font", profile.font), profile.font_size,
            outline ~= "" and outline or nil)
        text:ClearAllPoints()
        text:SetPoint("BOTTOM", button, "TOP", 0, profile.vertical_position)
    end
    entry.compact:SetAlpha(1)
    text:SetShown(current.showDurations and style.showTimerText ~= false)
    if button.bbfBinding then
        button.bbfBinding:SetFormatter(current.formatter)
        button.bbfBinding:SetTextColorCurve(current.color, Enum.DurationTextBindingProperty.RemainingDuration)
    else
        button:SetDurationText(text, { textFormatter = current.formatter,
            textColor = { curve = current.color, property = Enum.DurationTextBindingProperty.RemainingDuration } })
        button:SetDurationCooldown(cooldown)
    end
    cooldown:SetMinimumCountdownDuration(0)
    cooldown:SetCountdownFormatter(current.hoverFormatter or current.formatter)
    cooldown:SetHideCountdownNumbers(not (profile.detailed_time_on_hover and current.showDurations
        and style.showTimerText ~= false))
    -- BBF keeps its optional swipe and skin; only the native countdown text is
    -- used for detailed hover. No aura identity or remaining-time read is needed.
    local hoverText = entry.hoverText
    hoverText:SetFont(text:GetFont())
    hoverText:ClearAllPoints()
    -- GetPoint can return secret layout values (or no anchor). Anchor to the
    -- existing label itself, using only public arguments, instead of copying it.
    hoverText:SetPoint("CENTER", text, "CENTER", 0, 0)
    hoverText:SetDrawLayer("OVERLAY", 7)
    hoverText:SetAlpha(0)
    entry.config = current
end

local function RefreshBBFImbues()
    if not bbfActive or not current then return end
    local host = BBFHost()
    for _, button in ipairs(host and host.imbueHolder and host.imbueHolder.bbfButtons or {}) do
        if CanAccess(button) then ConfigureBBFButton(button, host.enchantStyle) end
    end
end

local function HookBBFContainer(container, host)
    if not container or container.buffTimersHooked then return end
    container.buffTimersHooked = true
    for _, method in ipairs({ "AddAuraGroup", "AddItemEnchantment" }) do
        local original = container[method]
        local enchantment = method == "AddItemEnchantment"
        if original then
            container[method] = function(self, key, filterOrOptions, groupOptions)
                local options = CopyTable((enchantment and filterOrOptions or groupOptions) or {})
                local initialize = options.initializeFrame
                options.initializeFrame = function(button)
                    if initialize then initialize(button) end
                    -- Blizzard permits initialization before restricting the new
                    -- button, including buttons allocated while auras are secret.
                    if available and bbfActive and BuffTimersNativeDB.enabled then
                        ConfigureBBFButton(button, enchantment and host.enchantStyle
                            or self.bbfStyles and self.bbfStyles[key])
                    end
                end
                if enchantment then return original(self, key, options) end
                return original(self, key, filterOrOptions, options)
            end
        end
    end
end

RestoreBBF = function()
    local hasManaged = bbfActive
    for _, entry in pairs(bbfEntries) do if entry.managed then hasManaged = true; break end end
    if not hasManaged then return end
    bbfActive = false
    bbfBusy = true
    local pending = false
    for button, entry in pairs(bbfEntries) do
        local accessible = CanAccess(button) and CanAccess(entry.text) and CanAccess(entry.compact)
            and CanAccess(entry.hoverText) and CanAccess(entry.cooldown)
        for _, region in ipairs(entry.art) do if not CanAccess(region) then accessible = false end end
        if entry.managed and accessible then
            entry.compact:SetAlpha(1)
            entry.hoverText:SetAlpha(0)
            entry.cooldown:SetHideCountdownNumbers(entry.oldHideNumbers)
            entry.cooldown:SetCountdownFormatter(entry.oldFormatter)
            if entry.ownsCooldown then
                if not entry.binding then button:ClearDurationCooldown() end
                entry.cooldown:Hide()
            end
            if button.bbfBinding then
                button.bbfBinding:SetFormatter(AuraContainerInbound.GetDefaultAuraDurationFormatter())
                button.bbfBinding:SetTextColorCurve(entry.style.durationCurve, Enum.DurationTextBindingProperty.RemainingDuration)
            else
                button:SetDurationText(entry.text, { textColor = {
                    curve = entry.style.durationCurve, property = Enum.DurationTextBindingProperty.RemainingDuration } })
            end
            -- Force BBF's own style pass to restore its timer color binding.
            button.bbfDurationCurve = nil
            for _, region in ipairs(entry.art) do if CanAccess(region) then region:SetAlpha(1) end end
            entry.managed, entry.config = false, nil
        elseif entry.managed then
            pending = true
        end
    end
    if pending then bbfBusy = false; return end
    local ok, reason = pcall(function()
        if BBF and BBF.RestyleAuraButtons then BBF.RestyleAuraButtons(true) end
        if BBF and BBF.RefreshPlayerAuraFrames then BBF.RefreshPlayerAuraFrames() end
    end)
    bbfBusy = false
    if not ok then error(reason) end
end

RefreshBBF = function()
    local host = BBFHost()
    if not host or not current or not BuffTimersNativeDB.enabled then return end
    bbfActive = true
    local seen = {}
    for _, key in ipairs({ "buffs", "blockTop", "blockBottom", "filtered" }) do
        local container = host[key]
        if container and not seen[container] and container.bbfStyles then
            seen[container] = true
            HookBBFContainer(container, host)
            for group, style in pairs(container.bbfStyles) do
                for i = 1, container:GetAuraGroupFrameCount(group) do
                    local button = container:GetAuraGroupFrame(group, i)
                    if button and CanAccess(button) then ConfigureBBFButton(button, style) end
                end
            end
        end
    end
    for _, button in ipairs(host.enchantButtons or {}) do
        if CanAccess(button) then ConfigureBBFButton(button, host.enchantStyle) end
    end
    for _, button in ipairs(host.imbueHolder and host.imbueHolder.bbfButtons or {}) do
        if CanAccess(button) then ConfigureBBFButton(button, host.enchantStyle) end
    end
end

local function HookBBF()
    if bbfHooked or not BBF or not BBF.RestyleAuraButtons then return end
    bbfHooked = true
    local function restyled()
        if bbfBusy or not available or not BuffTimersNativeDB.enabled or not BBFHost() then return end
        if not bbfActive then
            if not ConfigurationRestricted() then SafeRefresh() end
            return
        end
        for _, entry in pairs(bbfEntries) do entry.config = nil end
        if ConfigurationRestricted() then RefreshBBFImbues() else RefreshBBF() end
    end
    for _, method in ipairs({ "RestyleAuraButtons", "RefreshPlayerAuraFrames", "HookPlayerAndTargetAuras", "AnchorPlayerAuraContainer" }) do
        if BBF[method] then hooksecurefunc(BBF, method, restyled) end
    end
end

local function UpdateBBFVisuals()
    if not bbfActive or not active then return end
    -- These are BBF's ordinary weapon-enchant cells, not private aura buttons.
    -- New imbues can appear in combat; configure them without aura enumeration.
    RefreshBBFImbues()
    for _, entry in pairs(bbfEntries) do
        local text, hover, cooldown = entry.text, entry.hoverText, entry.cooldown
        if entry.managed and CanAccess(text) and CanAccess(entry.compact) and CanAccess(hover)
            and CanAccess(cooldown) and CanAccess(entry.hit) then
            if entry.binding then
                entry.binding:SetEnabled(true)
                cooldown:SetCooldownFromDurationObject(entry.duration, true)
            end
            local r, g, b, a = text:GetTextColor()
            local timed = cooldown:IsShown()
            for _, region in ipairs(entry.art) do
                if CanAccess(region) then region:SetAlphaFromBoolean(timed, a, 1) end
            end
            hover:SetTextColor(r, g, b, a)
            if current.profile.detailed_time_on_hover and current.showDurations and entry.style.showTimerText ~= false then
                local over = entry.hit:IsMouseOver()
                entry.compact:SetAlphaFromBoolean(over, 0, 1)
                hover:SetAlphaFromBoolean(over, 1, 0)
            else
                entry.compact:SetAlpha(1)
                hover:SetAlpha(0)
            end
        end
    end
end

local function Configure(entry)
    local config, button, icon, text = current, entry.button, entry.icon, entry.text
    entry.textFrame:SetAlpha(entry.hover and 0 or 1)
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
    if not entry.hover or (config.showDurations and config.profile.detailed_time_on_hover) then
        -- Keep the compact binding alive when timer numbers are hidden: its
        -- native color alpha also drives expiration flashing for the icon.
        text:SetShown(config.showDurations)
        button:SetDurationText(text, {
            textFormatter = entry.hover and config.hoverFormatter or config.formatter,
            textColor = { curve = config.color, property = Enum.DurationTextBindingProperty.RemainingDuration },
        })
    else
        button:ClearDurationText()
        text:Hide()
    end
end

local function InitializeButton(button, enchant, hover, container)
    local icon = button:CreateTexture(nil, "BACKGROUND")
    local warningArt = {}
    icon:SetSize(30, 30)
    if not hover then
        if enchant and C_Item and C_Item.GetWeaponEnchantInfo and C_PaperDollInfo
            and C_PaperDollInfo.GetTemporaryEnchantmentInfo and AuraContainerItemEnchantmentToInventorySlot
            and Enum.WeaponSlot then
            -- Keep this icon addon-owned: fixed enchant information is public,
            -- while adopted native aura regions become inaccessible in combat.
            -- Anchoring to the native icon proxy follows its secret layout
            -- without querying coordinates, visibility or aura identities.
            if not enchantHost then enchantHost = CreateFrame("Frame", nil, BuffFrame) end
            local frame = CreateFrame("Frame", nil, enchantHost, "DisableUntrustedLayoutScriptsTemplate")
            frame:SetAllPoints(icon)
            frame:SetFrameLevel(container:GetFrameLevel())
            local image = frame:CreateTexture(nil, "ARTWORK")
            warningArt[#warningArt + 1] = image
            image:SetAllPoints()
            frame:Hide()
            local weaponSlots = {
                [AuraContainerItemEnchantmentSlot.MainHand] = Enum.WeaponSlot.MainHand,
                [AuraContainerItemEnchantmentSlot.OffHand] = Enum.WeaponSlot.OffHand,
                [AuraContainerItemEnchantmentSlot.Ranged] = Enum.WeaponSlot.Ranged,
            }
            enchantIcons[#enchantIcons + 1] = { frame = frame, texture = image,
                inventorySlot = AuraContainerItemEnchantmentToInventorySlot[enchant], weaponSlot = weaponSlots[enchant] }
        else
            button:SetIcon(icon)
            warningArt[#warningArt + 1] = icon
        end
        local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
        button:SetApplicationCount(count)
        warningArt[#warningArt + 1] = count
    end
    -- Keep opacity on a separate parent so the native duration binding can
    -- update the FontString's color/alpha without revealing both timer labels.
    local textFrame = CreateFrame("Frame", nil, button,
        "DisableUntrustedScriptsTemplate,DisableUntrustedLayoutScriptsTemplate")
    textFrame:SetAllPoints(button)
    local text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetDrawLayer("OVERLAY", 1)
    -- This sibling stays addon-owned, including when native buttons restrict
    -- access in combat. Its geometry follows the button without reading it.
    local hoverRegion = CreateFrame("Frame", nil, BuffFrame, "DisableUntrustedLayoutScriptsTemplate")
    hoverRegion:SetAllPoints(button)
    if not hover and enchant then
        local border = button:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-TempEnchant-Border")
        border:SetSize(32, 32)
        border:SetPoint("CENTER", icon, "CENTER")
        warningArt[#warningArt + 1] = border
    end
    -- Native aura buttons propagate input. Only the main renderer cancels auras,
    -- so the overlay cannot turn one right-click into two cancellation attempts.
    button:SetCancelAuraButtons(not hover and "RightButtonUp" or nil)
    local entry = { button = button, icon = icon, text = text, hover = hover,
        textFrame = textFrame, hoverRegion = hoverRegion, warningArt = warningArt }
    if not hover then
        -- Native cooldown visibility distinguishes timed/permanent assignments,
        -- including reuse of a formerly flashing slot for a permanent buff.
        local cooldown = CreateFrame("Cooldown", nil, button,
            "DisableUntrustedScriptsTemplate,DisableUntrustedLayoutScriptsTemplate")
        cooldown:SetAllPoints(icon)
        cooldown:SetDrawSwipe(false)
        cooldown:SetDrawEdge(false)
        cooldown:SetDrawBling(false)
        cooldown:SetHideCountdownNumbers(true)
        cooldown:SetAlpha(0)
        button:SetDurationCooldown(cooldown)
        entry.warningCooldown = cooldown
    end
    buttons[#buttons + 1] = entry
    Configure(entry)
end

local function UpdateWarnings()
    if not active or bbfActive then return end
    for _, entry in ipairs(buttons) do
        local cooldown = entry.warningCooldown
        if cooldown and CanAccess(cooldown) and CanAccess(entry.text) then
            local _, _, _, alpha = entry.text:GetTextColor()
            -- Both values can be secret. Only native display setters consume
            -- them; no comparison, arithmetic, or branching on aura state.
            local timed = cooldown:IsShown()
            for _, region in ipairs(entry.warningArt) do
                if CanAccess(region) then region:SetAlphaFromBoolean(timed, alpha, 1) end
            end
        end
    end
end

local function UpdateHover()
    if not active or bbfActive or not current.showDurations or not current.profile.detailed_time_on_hover then return end
    -- Keep both labels in their previous state if any related frame is locked;
    -- updating only one side of the swap could expose overlapping text.
    for _, entry in ipairs(buttons) do
        if not CanAccess(entry.textFrame) or not CanAccess(entry.hoverRegion) then return end
    end
    for _, entry in ipairs(buttons) do
        -- Mouseover can be secret when anchored to a secret layout. Pass
        -- it straight to the native alpha setter; never branch on it in Lua.
        entry.textFrame:SetAlphaFromBoolean(entry.hoverRegion:IsMouseOver(),
            entry.hover and 1 or 0, entry.hover and 0 or 1)
    end
end

local function CreateNativeContainer(hover)
    local container = CreateFrame("AuraContainer", nil, BuffFrame, "CustomAuraContainerTemplate")
    container:SetEnabled(false)
    container:SetEditModePreviewEnabled(false)
    container:SetUnit("player")
    container:AddAuraGroup("buffs", "HELPFUL", {
        maxFrameCount = BuffFrame.maxAuras,
        sortMethod = AuraContainerSortMethod.AuraInstanceIDOnly,
        initializeFrame = function(button) InitializeButton(button, nil, hover, container) end,
    })
    for _, slot in ipairs({ AuraContainerItemEnchantmentSlot.MainHand, AuraContainerItemEnchantmentSlot.OffHand,
        AuraContainerItemEnchantmentSlot.Ranged }) do
        container:AddItemEnchantment(slot, { initializeFrame = function(button) InitializeButton(button, slot, hover, container) end })
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

local function UpdateEnchantIcons()
    if not active or bbfActive then return end
    for _, entry in ipairs(enchantIcons) do
        -- A frame being addon-created does not guarantee continued access once
        -- it depends on native aura layout. Keep its last icon until accessible.
        if CanAccess(entry.frame) and CanAccess(entry.texture) then
            local info = C_PaperDollInfo.GetTemporaryEnchantmentInfo(entry.inventorySlot)
            if info then
                local texture = GetInventoryItemTexture("player", entry.inventorySlot)
                if CVarCallbackRegistry:GetCVarValueBool("displayTemporaryEnchantIcon") then
                    for _, enchant in pairs(C_Item.GetWeaponEnchantInfo(entry.weaponSlot)) do
                        if enchant.hasEnchant and enchant.enchantID == info.enchantID then
                            texture = enchant.enchantIconID
                            break
                        end
                    end
                end
                entry.texture:SetTexture(texture)
                entry.frame:Show()
            else
                entry.frame:Hide()
            end
        end
    end
end

local function UnsupportedReason()
    -- BlizzBuffsFacade adds Blizzard's original BuffFrame.auraFrames to Masque.
    -- Native mode hides those buttons, which would hide every Masque skin.
    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("BlizzBuffsFacade") then
        return "BlizzBuffsFacade skins Blizzard's buff buttons. Using the existing renderer so its skins stay visible."
    end
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
    if ConfigurationRestricted() then return end
    HookBBF()
    if not BuffTimersNativeDB.enabled then Restore(); return end
    local profile, layout = BuffTimers.db.profile, BuffFrame.AuraContainer
    local host = BBFHost()
    local reason = not host and UnsupportedReason()
    if reason then
        Restore()
        if applied ~= reason then Message(reason) end
        applied = reason
        return
    end
    if not host and BuffFrame:IsEditing() then Restore(); applied = nil; return end

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
    parts[#parts + 1] = tostring(BuffTimersNativeDB.blink ~= false)
    parts[#parts + 1] = tostring(host ~= nil)
    local signature = table.concat(parts, ":")
    if active and applied == signature and not host then return end

    if host and originalsHidden then Restore() end
    if bbfActive and applied ~= signature then RestoreBBF() end

    local horizontal, right, top = layout.isHorizontal, layout.addIconsToRight, layout.addIconsToTop
    if not active or not current or applied ~= signature then current = {
        profile = CopyTable(profile),
        formatter = MakeFormatter(profile), color = MakeColorCurve(profile, BuffTimersNativeDB.blink ~= false),
        hoverFormatter = profile.detailed_time_on_hover and MakeHoverFormatter(profile) or nil,
        showDurations = showDurations,
        width = horizontal and 30 or 60, height = horizontal and 40 or 30,
        iconPoint = horizontal and (top and "BOTTOM" or "TOP") or (right and "LEFT" or "RIGHT"),
        durationPoint = horizontal and (top and "BOTTOM" or "TOP") or (right and "LEFT" or "RIGHT"),
        durationRelativePoint = horizontal and (top and "TOP" or "BOTTOM") or (right and "RIGHT" or "LEFT"),
    } end
    if host then
        RefreshBBF()
        active = true
        applied = signature
        return
    end
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
    if enchantHost then enchantHost:Show() end
    active = true
    UpdateHover()
    SetOriginalsVisible(false)
    originalsHidden = true
    ResizeHost(BuffFrame.maxAuras + 3)
    applied = signature
end

SafeRefresh = function()
    local ok, reason = pcall(function()
        Refresh()
        UpdateEnchantIcons()
    end)
    if not ok then
        local wasEnabled = BuffTimersNativeDB.enabled
        -- Persist the fallback before cleanup. An error in recovery must not
        -- leave the failing renderer enabled and retrying every ticker pulse.
        BuffTimersNativeDB.enabled = false
        active = false
        pcall(Restore)
        if wasEnabled then Message("Native mode stopped: " .. tostring(reason)) end
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
    if ConfigurationRestricted() or not available then return false end
    BuffTimersNativeDB.enabled = enabled == true
    SafeRefresh()
    return true
end

function Native:GetBlinkEnabled()
    return not BuffTimersNativeDB or BuffTimersNativeDB.blink ~= false
end

function Native:SetBlinkEnabled(enabled)
    if ConfigurationRestricted() or not available then return false end
    BuffTimersNativeDB.blink = enabled == true
    SafeRefresh()
    return true
end

function Native:GetStatus()
    if not self:GetNativeEnabled() then return "" end
    if not available then return "Native aura APIs are unavailable on this client. Using the existing renderer." end
    if bbfActive and active then return "" end
    local reason = UnsupportedReason()
    if reason then return reason end
    if BuffFrame:IsEditing() then return "Native buff timers are paused during Edit Mode." end
    if active then return "" end
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
        if active and not bbfActive and not BBFHost() then ResizeHost(BuffFrame.maxAuras + 3) end
    end)
    -- The legacy OnUpdate reapplies warning-flash alpha every tick. Keep those
    -- original buttons suppressed without inspecting its potentially secret alpha.
    for _, button in ipairs(BuffFrame.auraFrames) do
        if not button.isAuraAnchor then
            hooksecurefunc(button, "SetAlpha", function(original)
                if originalsHidden and not suppressingAlpha then
                    suppressingAlpha = true
                    original:SetAlpha(0)
                    suppressingAlpha = false
                end
            end)
        end
    end
    hoverDriver = CreateFrame("Frame")
    hoverDriver:SetScript("OnUpdate", function() UpdateBBFVisuals(); UpdateWarnings(); UpdateHover() end)
    timer = C_Timer.NewTicker(0.25, SafeRefresh)
    SafeRefresh()
end

function Native:OnDisable()
    available = false
    if hoverDriver then hoverDriver:SetScript("OnUpdate", nil); hoverDriver = nil end
    if timer then timer:Cancel(); timer = nil end
    Restore()
end
