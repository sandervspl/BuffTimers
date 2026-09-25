local Helpers = dofile("Tests/helpers.lua")

describe("profile import and export", function()
    it("exports every supported setting with a versioned BuffTimers prefix", function()
        local env = Helpers.loadAddon({
            profileName = "Raid Profile",
            profile = {
                time_stamp = "hm",
                seconds = true,
                detailed_time_on_hover = true,
                font = "A Font With Spaces",
                font_outline = "THICK",
            },
        })
        env.addon.db.profile.unrelated = "must not be exported"

        local exportString = env.addon:ExportProfile()

        assert.equals("BuffTimers:2:^1mock^^", exportString)
        assert.equals("Raid Profile", env.serializeRequest.profile_name)
        assert.same(Helpers.defaultProfile({
            time_stamp = "hm",
            seconds = true,
            detailed_time_on_hover = true,
            font = "A Font With Spaces",
            font_outline = "THICKOUTLINE",
        }), env.serializeRequest.profile)
        assert.is_nil(env.serializeRequest.profile.unrelated)
    end)

    it("creates and activates a profile with the exact exported name", function()
        local imported = Helpers.defaultProfile({
            time_stamp = "hm",
            seconds = true,
            seconds_threshold = 45,
            vertical_position = 0,
            font = "Imported Font",
            font_size = 22,
            font_outline = "THICK",
        })
        imported.unrelated = "must not be imported"
        local exportedName = "  Raid Team / Mythic  "

        local env = Helpers.loadAddon({
            profileName = "Original",
            profile = { yellow_text = true },
            deserialize = function(value)
                assert.equals("^1payload^^", value)
                return true, {
                    profile_name = exportedName,
                    profile = imported,
                }
            end,
        })
        local originalProfile = env.addon.db.profile

        assert.is_false(env.addon:WillImportReplaceProfile("BuffTimers:2:^1payload^^"))

        local success, importedName = env.addon:ImportProfile("  BuffTimers:2:^1payload^^\n")

        assert.is_true(success)
        assert.equals(exportedName, importedName)
        assert.same({ exportedName }, env.profileSetRequests)
        assert.equals(exportedName, env.addon.db:GetCurrentProfile())
        assert.equals(1, env.profileResetCount)
        assert.same(Helpers.defaultProfile({
            time_stamp = "hm",
            seconds = true,
            seconds_threshold = 45,
            vertical_position = 0,
            font = "Imported Font",
            font_size = 22,
            font_outline = "THICKOUTLINE",
        }), env.addon.db.profile)
        assert.is_nil(env.addon.db.profile.unrelated)
        assert.is_true(originalProfile.yellow_text)
        assert.equals(originalProfile, env.addon.db.profiles.Original)
    end)

    it("replaces an existing profile with the exported name instead of renaming it", function()
        local imported = Helpers.defaultProfile({ seconds = true })
        local env = Helpers.loadAddon({
            deserialize = function()
                return true, {
                    profile_name = "Shared",
                    profile = imported,
                }
            end,
        })
        env.addon.db.profiles.Shared = Helpers.defaultProfile({ yellow_text = true })
        env.addon.db.profiles.Shared.unrelated = true

        assert.is_true(env.addon:WillImportReplaceProfile("BuffTimers:2:^1payload^^"))

        local success, importedName = env.addon:ImportProfile("BuffTimers:2:^1payload^^")

        assert.is_true(success)
        assert.equals("Shared", importedName)
        assert.equals("Shared", env.addon.db:GetCurrentProfile())
        assert.is_true(env.addon.db.profile.seconds)
        assert.is_false(env.addon.db.profile.yellow_text)
        assert.is_nil(env.addon.db.profile.unrelated)
    end)

    it("keeps version 1 imports on the active profile because they have no exported name", function()
        local imported = Helpers.defaultProfile({ seconds = true })
        local env = Helpers.loadAddon({
            profileName = "Legacy Target",
            deserialize = function()
                return true, imported
            end,
        })

        assert.is_true(env.addon:WillImportReplaceProfile("BuffTimers:1:^1payload^^"))

        local success, importedName = env.addon:ImportProfile("BuffTimers:1:^1payload^^")

        assert.is_true(success)
        assert.equals("Legacy Target", importedName)
        assert.equals("Legacy Target", env.addon.db:GetCurrentProfile())
        assert.is_true(env.addon.db.profile.seconds)
    end)

    it("defaults the hover setting when importing a profile exported before it existed", function()
        local imported = Helpers.defaultProfile()
        imported.detailed_time_on_hover = nil
        local env = Helpers.loadAddon({
            profile = { detailed_time_on_hover = true },
            deserialize = function()
                return true, { profile_name = "Older Profile", profile = imported }
            end,
        })

        local success = env.addon:ImportProfile("BuffTimers:2:^1payload^^")

        assert.is_true(success)
        assert.is_false(env.addon.db.profile.detailed_time_on_hover)
    end)

    it("rejects malformed and unsupported strings without changing the profile", function()
        local env = Helpers.loadAddon({ profile = { seconds = true } })
        local originalProfile = env.addon.db.profile

        assert.is_false(env.addon:WillImportReplaceProfile("not a profile"))

        local success, errorCode = env.addon:ImportProfile("not a profile")
        assert.is_false(success)
        assert.equals("INVALID_FORMAT", errorCode)

        success, errorCode = env.addon:ImportProfile("BuffTimers:3:^1payload^^")
        assert.is_false(success)
        assert.equals("UNSUPPORTED_VERSION", errorCode)

        success, errorCode = env.addon:ImportProfile("BuffTimers:2:broken")
        assert.is_false(success)
        assert.equals("INVALID_DATA", errorCode)

        assert.equals(originalProfile, env.addon.db.profile)
        assert.is_nil(env.profileResetCount)
    end)

    it("rejects invalid settings before resetting the active profile", function()
        local imported = Helpers.defaultProfile({ font_size = 101 })
        local env = Helpers.loadAddon({
            profile = { seconds = true },
            deserialize = function()
                return true, {
                    profile_name = "Invalid Settings",
                    profile = imported,
                }
            end,
        })
        local originalProfile = env.addon.db.profile

        local success, errorCode, field = env.addon:ImportProfile("BuffTimers:2:^1payload^^")

        assert.is_false(success)
        assert.equals("INVALID_VALUE", errorCode)
        assert.equals("font_size", field)
        assert.equals(originalProfile, env.addon.db.profile)
        assert.is_nil(env.profileResetCount)
    end)

    it("rejects a vertical position above 0", function()
        local imported = Helpers.defaultProfile({ vertical_position = 1 })
        local env = Helpers.loadAddon({
            deserialize = function()
                return true, {
                    profile_name = "Invalid Position",
                    profile = imported,
                }
            end,
        })

        local success, errorCode, field = env.addon:ImportProfile("BuffTimers:2:^1payload^^")

        assert.is_false(success)
        assert.equals("INVALID_VALUE", errorCode)
        assert.equals("vertical_position", field)
        assert.is_nil(env.profileResetCount)
    end)

    it("rejects an invalid exported profile name before switching profiles", function()
        local env = Helpers.loadAddon({
            profileName = "Original",
            deserialize = function()
                return true, {
                    profile_name = "   ",
                    profile = Helpers.defaultProfile(),
                }
            end,
        })

        local success, errorCode, field = env.addon:ImportProfile("BuffTimers:2:^1payload^^")

        assert.is_false(success)
        assert.equals("INVALID_VALUE", errorCode)
        assert.equals("profile_name", field)
        assert.equals("Original", env.addon.db:GetCurrentProfile())
        assert.same({}, env.profileSetRequests)
        assert.is_nil(env.profileResetCount)
    end)

    it("bounds input size before deserialization", function()
        local env = Helpers.loadAddon()

        local success, errorCode = env.addon:ImportProfile("BuffTimers:2:" .. string.rep("x", 10000))

        assert.is_false(success)
        assert.equals("TOO_LONG", errorCode)
        assert.is_nil(env.deserializeRequest)
    end)
end)
