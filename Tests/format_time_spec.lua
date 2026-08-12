local Helpers = dofile("Tests/helpers.lua")

describe("BuffTimers core formatting", function()
    local env

    before_each(function()
        env = Helpers.loadAddon({ modern = true })
    end)

    local defaultCases = {
        { 0, "0.0s" },
        { 4.99, "4.9s" },
        { 5, "5s" },
        { 59.9, "59s" },
        { 60, "1m" },
        { 61, "2m" },
        { 3599, "60m" },
        { 86399, "1440m" },
        { 86400, "1d" },
        { 172800, "2d" },
    }

    for _, case in ipairs(defaultCases) do
        local input = case[1]
        local expected = case[2]

        it("formats " .. input .. " seconds with the default profile", function()
            assert.equals(expected, env.addon:FormatTime(input))
        end)
    end

    local secondsCases = {
        { 4.99, "4.9s" },
        { 59, "59s" },
        { 60, "1:00" },
        { 61, "1:01" },
        { 1799, "29:59" },
        { 1800, "30m" },
    }

    for _, case in ipairs(secondsCases) do
        local input = case[1]
        local expected = case[2]

        it("honors the seconds threshold at " .. input .. " seconds", function()
            env.addon.db.profile = Helpers.defaultProfile({
                seconds = true,
                seconds_threshold = 30,
            })

            assert.equals(expected, env.addon:FormatTime(input))
        end)
    end

    it("can disable tenths below five seconds", function()
        env.addon.db.profile = Helpers.defaultProfile({
            seconds = true,
            milliseconds = false,
        })

        assert.equals("4s", env.addon:FormatTime(4.99))
    end)

    local hourCases = {
        { 3599, "1h" },
        { 3600, "1:00h" },
        { 3659, "1:01h" },
        { 7140, "1:59h" },
        { 7199, "2h" },
    }

    for _, case in ipairs(hourCases) do
        local input = case[1]
        local expected = case[2]

        it("formats hour mode at " .. input .. " seconds", function()
            env.addon.db.profile = Helpers.defaultProfile({ time_stamp = "hm" })

            assert.equals(expected, env.addon:FormatTime(input))
        end)
    end

    it("includes seconds in hour mode below the configured threshold", function()
        env.addon.db.profile = Helpers.defaultProfile({
            time_stamp = "hm",
            seconds = true,
            seconds_threshold = 120,
        })

        assert.equals("1:00:59", env.addon:FormatTime(3659))
    end)

    it("uses hardcoded defaults when initializing a new profile", function()
        env.addon:OnInitialize()

        assert.equals("BuffTimersDB", env.dbRequest.name)
        assert.is_true(env.dbRequest.defaultProfile)
        assert.same(Helpers.defaultProfile(), env.dbRequest.defaults.profile)
        assert.equals(env.database, env.addon.db)
    end)

    it("migrates supported values from the legacy options table", function()
        env = Helpers.loadAddon({
            oldOptions = {
                time_stamp = "hm",
                seconds = true,
                seconds_threshold = 15,
                yellow_text = true,
                font_size = 20,
            },
        })

        env.addon:OnInitialize()

        local profile = env.dbRequest.defaults.profile
        assert.equals("hm", profile.time_stamp)
        assert.is_true(profile.seconds)
        assert.equals(15, profile.seconds_threshold)
        assert.is_true(profile.yellow_text)
        assert.equals(20, profile.font_size)
    end)
end)

describe("BuffTimers duration colors", function()
    local env
    local duration

    before_each(function()
        env = Helpers.loadAddon({ modern = true })
        duration = Helpers.newDuration()
    end)

    it("applies the compatibility yellow above one minute", function()
        env.addon:SetDurationColor(duration, 60)

        assert.same({ 0.99999779462814, 0.81960606575012, 0, 1 }, duration.color)
    end)

    it("leaves Blizzard's color unchanged below one minute by default", function()
        env.addon:SetDurationColor(duration, 59)

        assert.equals(0, #duration.colorCalls)
    end)

    it("can force yellow at every duration", function()
        env.addon.db.profile.yellow_text = true

        env.addon:SetDurationColor(duration, 10)

        assert.same({ 0.99999779462814, 0.81960606575012, 0, 1 }, duration.color)
    end)

    local coloredCases = {
        { 600, { 0.1, 1, 0.1, 1 } },
        { 60, { 0.99999779462814, 0.81960606575012, 0, 1 } },
        { 59, { 1, 0.1, 0.1, 1 } },
    }

    for _, case in ipairs(coloredCases) do
        local input = case[1]
        local expected = case[2]

        it("applies the configured color band at " .. input .. " seconds", function()
            env.addon.db.profile.colored_text = true

            env.addon:SetDurationColor(duration, input)

            assert.same(expected, duration.color)
        end)
    end

    it("gives always-yellow precedence over colored bands", function()
        env.addon.db.profile.yellow_text = true
        env.addon.db.profile.colored_text = true

        env.addon:SetDurationColor(duration, 10)

        assert.same({ 0.99999779462814, 0.81960606575012, 0, 1 }, duration.color)
    end)
end)
