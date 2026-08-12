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

    it("hooks the legacy global aura functions", function()
        local env = Helpers.loadAddon({ modern = false })

        env.addon:OnEnable()

        assert.same({ "AuraButton_Update", env.addon.OnAuraUpdate }, env.hooks[1])
        assert.same({ "AuraButton_UpdateDuration", env.addon.OnAuraDurationUpdate }, env.hooks[2])
    end)
end)

describe("BuffTimers.OnAuraDurationUpdate", function()
    it("updates and shows modern duration text", function()
        local env = Helpers.loadAddon({ modern = true })
        local duration = Helpers.newDuration()
        local aura = { Duration = duration }

        env.addon.OnAuraDurationUpdate(aura, 61)

        assert.equals("2m", duration.text)
        assert.is_true(duration.visible)
        assert.same({ 0.99999779462814, 0.81960606575012, 0, 1 }, duration.color)
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
