local Helpers = dofile("Tests/helpers.lua")

describe("BuffTimers client integration", function()
    it("detects Blizzard's modern aura frame", function()
        local env = Helpers.loadAddon({ modern = true })

        assert.is_true(env.namespace.isNotClassic)
    end)

    it("detects Blizzard's legacy aura frame", function()
        local env = Helpers.loadAddon({ modern = false })

        assert.is_false(env.namespace.isNotClassic)
    end)

    it("hooks only the modern duration method", function()
        local buffButton = {
            OnUpdate = function() end,
            UpdateDuration = function() end,
        }
        local debuffButton = {
            UpdateDuration = function() end,
        }
        local env = Helpers.loadAddon({
            modern = true,
            modernFrames = {
                buffs = { buffButton },
                debuffs = { debuffButton },
            },
        })

        env.addon:OnEnable()

        assert.equals(2, #env.hooks)
        assert.same({ buffButton, "UpdateDuration", env.addon.OnAuraDurationUpdate }, env.hooks[1])
        assert.same({ debuffButton, "UpdateDuration", env.addon.OnAuraDurationUpdate }, env.hooks[2])
    end)

    it("reapplies custom text after Blizzard's locale-specific duration styling", function()
        local buffButton = {
            OnUpdate = function() end,
            UpdateDuration = function() end,
        }
        local env = Helpers.loadAddon({
            modern = true,
            modernFrames = { buffs = { buffButton } },
            smallerAuraDurationFont = true,
            profile = {
                customize_text = true,
                vertical_position = -45,
                font = "Mock Font",
                font_size = 18,
                font_outline = "OUTLINE",
            },
        })
        local duration = Helpers.newDuration()
        local aura = { Duration = duration }
        duration:SetPoint("TOP", aura, "BOTTOM", 0, -2)

        env.addon:OnEnable()

        assert.same({ buffButton, "UpdateDuration", env.addon.OnAuraDurationUpdate }, env.hooks[1])
        assert.same({ buffButton, "OnUpdate", env.addon.OnAuraFrameUpdate }, env.hooks[2])

        env.hooks[1][3](aura, 7200)
        duration:SetFontObject("GameFontHighlightSmall2")
        duration:SetPoint("TOP", aura, "BOTTOM", 0, -2)
        env.hooks[2][3](aura)

        assert.same({ "BOTTOM", aura, "TOP", 0, -45 }, duration.point)
        assert.equals(1, #duration.points)
        assert.same({ "Fonts\\Mock.ttf", 18, "OUTLINE" }, duration.font)
    end)

    it("hooks the legacy global aura functions", function()
        local env = Helpers.loadAddon({ modern = false })

        env.addon:OnEnable()

        assert.same({ "AuraButton_Update", env.addon.OnAuraUpdate }, env.hooks[1])
        assert.same({ "AuraButton_UpdateDuration", env.addon.OnAuraDurationUpdate }, env.hooks[2])
    end)
end)

describe("BuffTimers.OnAuraDurationUpdate", function()
    it("leaves Blizzard's text in place for a secret timer value", function()
        local secretTime = {}
        local env = Helpers.loadAddon({
            modern = true,
            profile = { detailed_time_on_hover = true },
            issecretvalue = function(value) return value == secretTime end,
        })
        local duration = Helpers.newDuration()
        duration.text = "Blizzard timer"
        local aura = {
            Duration = duration,
            IsMouseOver = function() error("secret time must not query hover") end,
        }
        local formatCalls = 0
        env.addon.FormatTime = function()
            formatCalls = formatCalls + 1
        end

        env.addon.OnAuraDurationUpdate(aura, secretTime)

        assert.equals(0, formatCalls)
        assert.equals("Blizzard timer", duration.text)
        assert.is_nil(duration.color)
    end)

    it("updates and shows modern duration text", function()
        local env = Helpers.loadAddon({
            modern = true,
            issecretvalue = function() return false end,
        })
        local duration = Helpers.newDuration()
        local aura = { Duration = duration }

        env.addon.OnAuraDurationUpdate(aura, 61)

        assert.equals("2m", duration.text)
        assert.is_true(duration.visible)
        assert.same({ 0.99999779462814, 0.81960606575012, 0, 1 }, duration.color)
    end)

    it("shows detailed time on hover only with minutes remaining", function()
        local env = Helpers.loadAddon({
            modern = true,
            profile = { detailed_time_on_hover = true },
        })
        local duration = Helpers.newDuration()
        local hovering = false
        local hoverChecks = 0
        local aura = {
            Duration = duration,
            IsMouseOver = function()
                hoverChecks = hoverChecks + 1
                return hovering
            end,
        }

        env.addon.OnAuraDurationUpdate(aura, 3661)
        assert.equals("62m", duration.text)

        hovering = true
        env.addon.OnAuraDurationUpdate(aura, 4.9)
        assert.equals("4.9s", duration.text)
        env.addon.OnAuraDurationUpdate(aura, 9)
        assert.equals("9s", duration.text)
        env.addon.OnAuraDurationUpdate(aura, 59.9)
        assert.equals("59s", duration.text)
        assert.equals(1, hoverChecks)
        env.addon.OnAuraDurationUpdate(aura, 60)
        assert.equals("01:00", duration.text)
        env.addon.OnAuraDurationUpdate(aura, 61)
        assert.equals("01:01", duration.text)
        env.addon.OnAuraDurationUpdate(aura, 3599)
        assert.equals("59:59", duration.text)
        env.addon.OnAuraDurationUpdate(aura, 3600)
        assert.equals("01:00:00", duration.text)
        env.addon.OnAuraDurationUpdate(aura, 3661)
        assert.equals("01:01:01", duration.text)
        env.addon.OnAuraDurationUpdate(aura, 90061)
        assert.equals("25:01:01", duration.text)

        hovering = false
        env.addon.OnAuraDurationUpdate(aura, 3661)
        assert.equals("62m", duration.text)
    end)

    it("tracks Blizzard's enter and leave scripts when mouse hit testing misses a buff", function()
        local duration = Helpers.newDuration()
        local scripts = {}
        local button = {
            Duration = duration,
            UpdateDuration = function() end,
            IsMouseOver = function() return false end,
            HookScript = function(_, name, callback) scripts[name] = callback end,
        }
        local env = Helpers.loadAddon({
            modern = true,
            modernFrames = { buffs = { button } },
            profile = { detailed_time_on_hover = true },
        })
        env.addon:OnEnable()

        env.addon.OnAuraDurationUpdate(button, 3661)
        assert.equals("62m", duration.text)

        scripts.OnEnter(button)
        env.addon.OnAuraDurationUpdate(button, 3661)
        assert.equals("01:01:01", duration.text)

        scripts.OnLeave(button)
        env.addon.OnAuraDurationUpdate(button, 3661)
        assert.equals("62m", duration.text)

        scripts.OnEnter(button)
        scripts.OnHide(button)
        env.addon.OnAuraDurationUpdate(button, 3661)
        assert.equals("62m", duration.text)
    end)

    it("updates the legacy lowercase duration region", function()
        local env = Helpers.loadAddon({ modern = false })
        local duration = Helpers.newDuration()

        env.addon.OnAuraDurationUpdate({ duration = duration }, 59)

        assert.equals("59s", duration.text)
        assert.is_true(duration.visible)
    end)

    it("hides duration text when no time is supplied", function()
        local env = Helpers.loadAddon({ modern = true })
        local duration = Helpers.newDuration()

        env.addon.OnAuraDurationUpdate({ Duration = duration }, nil)

        assert.is_false(duration.visible)
        assert.equals(1, duration.hideCount)
    end)

    it("applies custom positioning and normalizes the legacy thick outline", function()
        local env = Helpers.loadAddon({
            modern = true,
            profile = {
                customize_text = true,
                vertical_position = -40,
                font = "Mock Font",
                font_size = 18,
                font_outline = "THICK",
            },
        })
        local duration = Helpers.newDuration()
        local aura = { Duration = duration }

        env.addon.OnAuraDurationUpdate(aura, 30)

        assert.same({ "BOTTOM", aura, "TOP", 0, -39.9 }, duration.point)
        assert.same({ "Fonts\\Mock.ttf", 18, "THICKOUTLINE" }, duration.font)
        assert.same({ { mediaType = "font", name = "Mock Font" } }, env.mediaQueries)
    end)

    it("restores Blizzard's font and layering while preserving customization values", function()
        local env = Helpers.loadAddon({
            modern = true,
            profile = {
                customize_text = true,
                vertical_position = -45,
                font = "Mock Font",
                font_size = 18,
                font_outline = "OUTLINE",
            },
        })
        local duration = Helpers.newDuration()
        local aura = { Duration = duration }
        duration:SetPoint("TOP", aura, "BOTTOM", 2, -3)
        duration:SetDrawLayer("BACKGROUND", 2)

        env.addon.OnAuraDurationUpdate(aura, 30)

        assert.same({ "BOTTOM", aura, "TOP", 0, -45 }, duration.point)
        assert.equals(1, #duration.points)
        assert.same({ "Fonts\\Mock.ttf", 18, "OUTLINE" }, duration.font)
        assert.same({ "OVERLAY", 1 }, { duration:GetDrawLayer() })

        env.addon:SetTextCustomizationEnabled(false)

        assert.same({ "TOP", aura, "BOTTOM", 2, -3 }, duration.point)
        assert.equals(1, #duration.points)
        assert.equals("GameFontNormalSmall", duration.fontObject)
        assert.same({ "BACKGROUND", 2 }, { duration:GetDrawLayer() })
        assert.same({ "Fonts\\FRIZQT__.TTF", 10 }, duration.font)
        assert.equals(-45, env.addon.db.profile.vertical_position)
        assert.equals("Mock Font", env.addon.db.profile.font)
        assert.equals(18, env.addon.db.profile.font_size)
        assert.equals("OUTLINE", env.addon.db.profile.font_outline)

        env.addon.OnAuraDurationUpdate(aura, nil)
        assert.is_false(duration.visible)

        env.addon:SetTextCustomizationEnabled(true)
        env.addon.OnAuraDurationUpdate(aura, 28)

        assert.same({ "OVERLAY", 1 }, { duration:GetDrawLayer() })
        assert.same({ "BOTTOM", aura, "TOP", 0, -45 }, duration.point)
        assert.same({ "Fonts\\Mock.ttf", 18, "OUTLINE" }, duration.font)
        assert.same({ mediaType = "font", name = "Mock Font" }, env.mediaQueries[#env.mediaQueries])

        env.addon:SetTextCustomizationEnabled(false)
        assert.same({ "BACKGROUND", 2 }, { duration:GetDrawLayer() })
        assert.same({ "Fonts\\FRIZQT__.TTF", 10 }, duration.font)
        assert.equals(18, env.addon.db.profile.font_size)
    end)
end)

describe("BuffTimers.OnAuraUpdate on legacy clients", function()
    it("shows a legacy aura with an expiration time", function()
        local env = Helpers.loadAddon({ modern = false })
        local duration = Helpers.newDuration()
        _G.BuffButton7Duration = duration
        env.unitAuraResult = {
            [1] = "Power Word: Fortitude",
            [6] = 150,
            n = 6,
        }

        env.addon.OnAuraUpdate("BuffButton", 7, "HELPFUL")

        assert.is_true(duration.visible)
        assert.same({ { "player", 7, "HELPFUL" } }, env.unitAuraQueries)
    end)

    it("hides a legacy aura without an expiration time", function()
        local env = Helpers.loadAddon({ modern = false })
        local duration = Helpers.newDuration()
        _G.DebuffButton3Duration = duration
        env.unitAuraResult = {
            [1] = "Weakened Soul",
            [6] = 0,
            n = 6,
        }

        env.addon.OnAuraUpdate("DebuffButton", 3, "HARMFUL")

        assert.is_false(duration.visible)
    end)

    it("returns safely when the legacy duration region is absent", function()
        local env = Helpers.loadAddon({ modern = false })
        _G.BuffButton99Duration = nil

        env.addon.OnAuraUpdate("BuffButton", 99, "HELPFUL")

        assert.equals(0, #env.unitAuraQueries)
    end)
end)
