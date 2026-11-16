-- Loaded by forever-native-replay.lua with BUFFTIMERS_TEST_BBF=true.
-- Contract fixture for BBF v2.2.2c native player hosts, based on the installed
-- retail/forever modules/auras.lua. Does not emulate WoW's security engine.
-- Failure cases: duplicate grids, changing filters/skins, touching target/debuff
-- timers, restyles overwriting formatting, late buttons during secret auras,
-- permanent/temporary enchants, hover overlap, and incomplete opt-out cleanup.
return function(ctx)
    local region, check = ctx.region, ctx.check
    local defaultFormatter = C_StringUtil.CreateNumericRuleFormatter()
    defaultFormatter:SetBreakpoints({ { threshold = 0, format = "BBF default" } })
    AuraContainerInbound = { GetDefaultAuraDurationFormatter = function() return defaultFormatter end }
    local defaultCurve = C_CurveUtil.CreateColorCurve()
    defaultCurve:SetType(Enum.LuaCurveType.Step)
    defaultCurve:AddPoint(0, CreateColor(1, 0.8, 0, 1))
    local styles = {
        normal = { durationCurve = defaultCurve, showTimerText = true },
        important = { durationCurve = defaultCurve, showTimerText = true },
    }
    local players, all = {}, {}
    local function styleButton(button, style)
        button.bbfTimer:SetFont("bbf.ttf", 12, "OUTLINE")
        button.bbfTimer:ClearAllPoints()
        button.bbfTimer:SetPoint("TOP", button.bbfIcon, "BOTTOM", 0, -1)
        button.bbfTimer:SetShown(style.showTimerText)
        if button.bbfDurationCurve ~= style.durationCurve then
            button.bbfDurationCurve = style.durationCurve
            if button.bbfBinding then
                button.bbfBinding:SetTextColorCurve(style.durationCurve, Enum.DurationTextBindingProperty.RemainingDuration)
            else
                button:SetDurationText(button.bbfTimer, { textFormatter = defaultFormatter,
                    textColor = { curve = style.durationCurve, property = Enum.DurationTextBindingProperty.RemainingDuration } })
            end
        end
    end
    local function button(ordinary, withCooldown)
        local b = region(not ordinary)
        b.initializing = true
        b.bbfIcon = b:CreateTexture(nil, "BACKGROUND")
        b.bbfIcon.mask = "BBF Masque skin"
        b.bbfCount = b:CreateFontString(nil, "OVERLAY")
        b.bbfBorder = b:CreateTexture(nil, "OVERLAY")
        local textLayer = region(false)
        if not ordinary then b.bbfTextLayer = textLayer end
        b.bbfTimer = textLayer:CreateFontString(nil, "OVERLAY")
        -- Native layout anchors may be secret even though the FontString object
        -- itself is accessible. They cannot be copied into tainted SetPoint.
        function b.bbfTimer:GetPoint() error("attempted to read native timer anchors") end
        b:SetSize(30, 40)
        if ordinary or withCooldown then
            b.bbfCooldown = CreateFrame("Cooldown", nil, b)
            b.bbfCooldown:SetDrawSwipe(true)
            b.bbfCooldown:SetHideCountdownNumbers(true)
            b.bbfCooldown.owner = b
        end
        if ordinary then
            b.bbfDuration = { owner = b }
            b.duration = { b.bbfTimer, { textFormatter = defaultFormatter,
                textColor = { curve = defaultCurve } } }
            b.bbfTimer.owner = b
            b.bbfBinding = {
                SetFormatter = function(_, formatter) b.duration[2].textFormatter = formatter end,
                SetTextColorCurve = function(_, curve) b.duration[2].textColor.curve = curve end,
                SetEnabled = function(_, enabled) b.bindingEnabled = enabled end,
            }
            b.SetDurationText, b.ClearDurationCooldown = nil, nil
        end
        b.style = styles.normal
        styleButton(b, b.style)
        b.initializing = false
        all[#all + 1] = b
        return b
    end
    local function container()
        local c = region(false)
        c.bbfStyles, c.groups, c.filters, c.initializers = {}, {}, {}, {}
        function c:GetAuraGroupFrameCount(key) return #(self.groups[key] or {}) end
        function c:GetAuraGroupFrame(key, index) return self.groups[key][index] end
        function c:AddAuraGroup(key, filter, options)
            self.filters[key] = filter
            self.initializers[key] = options.initializeFrame
            self.groups[key] = {}
            local b = button(false)
            b.initializing = true
            options.initializeFrame(b)
            b.initializing = false
            self.groups[key][1] = b
            players[#players + 1] = b
            return key
        end
        function c:AllocateButton(key)
            local b = button(false)
            b.initializing = true
            self.initializers[key](b)
            b.initializing = false
            self.groups[key][#self.groups[key] + 1] = b
            players[#players + 1] = b
            return b
        end
        function c:AddItemEnchantment(slot, options)
            local b = button(false)
            b.initializing = true
            options.initializeFrame(b)
            b.initializing = false
            return b
        end
        return c
    end
    local buffs, filtered = container(), container()
    local first, important, hidden = button(false), button(false, true), button(false)
    important.style = styles.important
    buffs.bbfStyles, buffs.groups = styles, { normal = { first }, important = { important } }
    buffs.filters = { normal = "HELPFUL|!IMPORTANT", important = "HELPFUL|IMPORTANT" }
    filtered.bbfStyles, filtered.groups = { normal = styles.normal }, { normal = { hidden } }
    players = { first, important, hidden }
    local nativeEnchant, imbue = button(false), button(true)
    players[#players + 1], players[#players + 2] = nativeEnchant, imbue
    local target, debuff = button(false), button(false)
    local host = { frame = BuffFrame, isPlayer = true, buffs = buffs, blockTop = buffs, blockBottom = buffs,
        filtered = filtered, enchantStyle = styles.normal, enchantButtons = { nativeEnchant },
        imbueHolder = { bbfButtons = { imbue } } }
    local api = { auraHosts = { playerBuffs = host, target = { buffs = target }, playerDebuffs = { debuffs = debuff } } }
    function api.RestyleAuraButtons()
        for _, b in ipairs(all) do styleButton(b, b.style) end
    end
    function api.RefreshPlayerAuraFrames()
        for _, b in ipairs(players) do if b.bbfBinding then styleButton(b, b.style) end end
    end
    function api.HookPlayerAndTargetAuras() end
    function api.AnchorPlayerAuraContainer() styleButton(imbue, imbue.style) end
    if not BUFFTIMERS_TEST_BBF_LATE then BBF = api end
    return function(options, native)
        local rootsBefore = #ctx.containers
        BBF = api
        ctx.tick()
        local toggle = options.args.time.args.nativeTimers.args.enabled
        local blinking = options.args.time.args.nativeTimers.args.blinking
        check(native:IsNativeActive() and toggle.get(), "BBF player host uses native BuffTimers formatting")
        if not BUFFTIMERS_TEST_BBF_LATE then check(rootsBefore == 0, "BBF present at startup prevents standalone aura-grid creation") end
        check(#ctx.containers == rootsBefore, "BBF compatibility creates no competing aura containers")
        if rootsBefore > 0 then check(not ctx.containers[1].enabled, "late BBF ownership disables the standalone buff renderer") end
        check(first.duration[2].textFormatter:FormatNumber(6300) == "105m"
            and hidden.duration[2].textFormatter:FormatNumber(6300) == "105m",
            "normal, important and hidden-filter groups receive BuffTimers formatting")
        check(buffs.filters.normal == "HELPFUL|!IMPORTANT" and buffs.filters.important == "HELPFUL|IMPORTANT"
            and first.bbfIcon.mask == "BBF Masque skin" and first.SetSizeArgs[1] == 30,
            "BBF filters, skin and icon layout remain intact")
        check(target.duration[2].textFormatter == defaultFormatter and debuff.duration[2].textFormatter == defaultFormatter,
            "target and player debuff timers are not overridden")
        check(imbue.duration[2].textFormatter:FormatNumber(6300) == "105m"
            and nativeEnchant.duration[2].textFormatter:FormatNumber(6300) == "105m",
            "BBF native enchant slots and separate imbue bindings both use BuffTimers")
        ctx.profile.time_stamp = "hm"
        ctx.profile.detailed_time_on_hover = true
        ctx.tick()
        check(first.duration[2].textFormatter:FormatNumber(6300) == "1:45h", "BBF timer format follows profile changes")
        check(first.cooldown.formatter:FormatNumber(6300) == "01:45:00"
            and important.bbfCooldown.SetDrawSwipeValue == true,
            "detailed hover uses the native countdown channel and retains BBF's existing cooldown swipe")
        buffs.bbfStyles.extra = styles.normal
        buffs:AddAuraGroup("extra", "HELPFUL|RAID", { initializeFrame = function(b) b.fixtureInitialized = true end })
        ctx.setCombat(true)
        first.seconds, imbue.seconds = 30.25, 30.25
        ctx.update()
        check(math.abs(first.bbfIcon.alpha - 0.3) < 0.000001 and math.abs(imbue.bbfIcon.alpha - 0.3) < 0.000001,
            "BBF buffs and imbues flash during combat through accessible regions")
        ctx.setMouse(first, true)
        ctx.update()
        check(first.bbfTextLayer.alpha == 0 and first.cooldown.countdownText.alpha == 1,
            "BBF detailed hover swaps compact/countdown text without a background during combat")
        ctx.setMouse(first, false)
        ctx.update()
        check(first.bbfTextLayer.alpha == 1 and first.cooldown.countdownText.alpha == 0,
            "leaving BBF hover restores compact text")
        -- Simulate the native frame provider expanding an existing group while
        -- secret. Only the initialization callback may access that new button.
        ctx.setSecret(true)
        local extra = buffs:AllocateButton("extra")
        check(extra.fixtureInitialized and buffs.filters.extra == "HELPFUL|RAID"
            and extra.duration[2].textFormatter:FormatNumber(6300) == "1:45h",
            "new combat-allocated BBF buttons preserve the filter and original initialization callback")
        api.AnchorPlayerAuraContainer(host)
        check(imbue.duration[2].textFormatter:FormatNumber(6300) == "1:45h" and imbue.bbfTimer.SetFontArgs[2] == 10,
            "BBF weapon-enchant restyles during combat retain cached BuffTimers settings")
        ctx.profile.font_size = 18
        ctx.tick()
        check(first.bbfTimer.SetFontArgs[2] == 10, "BBF profile changes defer while aura access is restricted")
        ctx.setCombat(false)
        ctx.setSecret(false)
        ctx.tick()
        check(first.bbfTimer.SetFontArgs[2] == 18, "BBF deferred styling applies after restrictions end")
        api.RestyleAuraButtons(true)
        check(first.duration[2].textFormatter:FormatNumber(6300) == "1:45h"
            and first.bbfTimer.SetFontArgs[2] == 18, "BBF restyling reapplies BuffTimers formatting and text options")
        ctx.profile.customize_text = false
        ctx.tick()
        check(first.bbfTimer.SetFontArgs[1] == "bbf.ttf", "disabling BuffTimers text customization restores BBF's font")
        blinking.set(nil, false)
        ctx.update()
        check(first.bbfIcon.alpha == 1 and imbue.bbfIcon.alpha == 1,
            "disabling blinking restores full opacity on BBF buffs and weapon enchants")
        ctx.profile.colored_text = true
        ctx.tick()
        check(first.duration[2].textColor.curve:Evaluate(6300)[2] == 1,
            "BuffTimers color options apply to BBF timers")
        ctx.profile.customize_text = true
        ctx.tick()
        check(first.bbfTimer.SetFontArgs[2] == 18, "BBF opt-out starts from an actively customized timer")
        toggle.set(nil, false)
        check(not native:IsNativeActive() and first.duration[2].textFormatter == defaultFormatter
            and imbue.duration[2].textFormatter == defaultFormatter and first.bbfTimer.SetFontArgs[1] == "bbf.ttf",
            "opt-out restores BBF's native formatter, imbue binding and font")
        check(not first.cooldown and important.bbfCooldown:GetHideCountdownNumbers(),
            "opt-out removes owned countdown channels and restores BBF countdown visibility")
        toggle.set(nil, true)
        check(native:IsNativeActive() and first.duration[2].textFormatter:FormatNumber(6300) == "1:45h",
            "BBF integration can be re-enabled without creating duplicate aura grids")
        print("PASS BetterBlizzFrames native-host compatibility replay")
    end
end
