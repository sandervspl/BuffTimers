describe("profile options", function()
    local originalGlobals
    local nilValue = {}
    local globalNames = {
        "BuffTimersLibSharedMedia",
        "C_Timer",
        "CopyToClipboard",
        "LibStub",
        "MultiLineEditBox1Edit",
        "SLASH_BUFFTIMERS1",
        "SlashCmdList",
    }

    before_each(function()
        originalGlobals = {}
        for _, name in ipairs(globalNames) do
            originalGlobals[name] = _G[name] == nil and nilValue or _G[name]
        end
    end)

    after_each(function()
        for _, name in ipairs(globalNames) do
            local value = originalGlobals[name]
            _G[name] = value == nilValue and nil or value
        end
    end)

    it("uses AceDBOptions and wires profile import/export controls", function()
        local env = {
            importResult = { true, "Imported Profile" },
            notifyCount = 0,
            willReplaceProfile = false,
        }
        local module = {}
        local addon = {
            db = { profile = {} },
            VERTICAL_POSITION_MIN = -100,
            VERTICAL_POSITION_MAX = 0,
        }
        local profileOptions = { type = "group", name = "Profiles", args = {} }
        local locale = setmetatable({}, {
            __index = function(_, key) return key end,
        })

        function addon:NewModule(name)
            assert.equals("Config", name)
            return module
        end
        function addon:ExportProfile()
            env.exportCount = (env.exportCount or 0) + 1
            return "BuffTimers:2:export" .. env.exportCount
        end
        function addon:ImportProfile(value)
            env.importedText = value
            return unpack(env.importResult)
        end
        function addon:WillImportReplaceProfile(value)
            env.confirmedText = value
            return env.willReplaceProfile
        end
        function addon:SetTextCustomizationEnabled(value)
            env.customizationToggle = value
            self.db.profile.customize_text = value
        end

        local libraries = {
            ["AceAddon-3.0"] = {
                GetAddon = function(_, name)
                    assert.equals("BuffTimers", name)
                    return addon
                end,
            },
            ["AceLocale-3.0"] = {
                GetLocale = function(_, name)
                    assert.equals("BuffTimers", name)
                    return locale
                end,
            },
            ["LibSharedMedia-3.0"] = {},
            ["AceConfigRegistry-3.0"] = {
                RegisterOptionsTable = function(_, name, options)
                    env.registeredName = name
                    env.options = options
                end,
                NotifyChange = function(_, name)
                    assert.equals("BuffTimers", name)
                    env.notifyCount = env.notifyCount + 1
                end,
            },
            ["AceConfigDialog-3.0"] = {
                AddToBlizOptions = function(_, ...)
                    env.blizzardOptions = { ... }
                end,
                Open = function(_, name)
                    env.openedName = name
                end,
            },
            ["AceDBOptions-3.0"] = {
                GetOptionsTable = function(_, db)
                    env.profileDB = db
                    return profileOptions
                end,
            },
            ["AceGUI-3.0"] = {
                GetWidgetCount = function(_, widgetType)
                    assert.equals("MultiLineEditBox", widgetType)
                    return 1
                end,
            },
        }

        _G.LibStub = function(name)
            return assert(libraries[name], "unexpected library lookup: " .. tostring(name))
        end
        _G.C_Timer = {
            After = function(delay, callback)
                env.selectionDelay = delay
                env.selectionCallback = callback
            end,
        }
        _G.CopyToClipboard = function()
            env.restrictedClipboardCalled = true
            error("protected function must not be called")
        end
        _G.MultiLineEditBox1Edit = {
            IsVisible = function() return true end,
            GetText = function() return env.visibleExportText end,
            SetFocus = function() env.exportFocused = true end,
            HighlightText = function() env.exportHighlighted = true end,
        }
        _G.SlashCmdList = {}

        assert(loadfile("Options.lua"))()
        module:OnInitialize()

        assert.equals("BuffTimers", env.registeredName)
        assert.equals(addon.db, env.profileDB)
        assert.equals(profileOptions, env.options.args.profiles)
        assert.equals(20, profileOptions.order)
        assert.same({ "BuffTimers", "BuffTimers" }, env.blizzardOptions)

        local detailedTimeOnHover = env.options.args.time.args.formatGroup.args.detailedTimeOnHover
        detailedTimeOnHover.set(nil, true)
        assert.is_true(detailedTimeOnHover.get())
        assert.is_true(addon.db.profile.detailed_time_on_hover)

        local verticalPosition = env.options.args.textGroup.args.customizeTextGroup.args.verticalPosition
        assert.equals(-100, verticalPosition.min)
        assert.equals(0, verticalPosition.max)

        local customization = env.options.args.textGroup.args.customizeTextGroup.args
        local fontOptions = customization.fontGroup.args
        assert.is_true(verticalPosition.disabled())
        assert.is_true(fontOptions.font.disabled())
        assert.is_true(fontOptions.fontSize.disabled())
        assert.is_true(fontOptions.fontOutline.disabled())

        customization.enableCustomizeText.set(nil, true)
        assert.is_false(verticalPosition.disabled())
        assert.is_false(fontOptions.font.disabled())
        assert.is_false(fontOptions.fontSize.disabled())
        assert.is_false(fontOptions.fontOutline.disabled())

        addon.db.profile.vertical_position = -45
        addon.db.profile.font = "Custom Font"
        addon.db.profile.font_size = 22
        addon.db.profile.font_outline = "THICKOUTLINE"
        customization.enableCustomizeText.set(nil, false)
        assert.is_false(env.customizationToggle)
        assert.equals(-45, addon.db.profile.vertical_position)
        assert.equals("Custom Font", addon.db.profile.font)
        assert.equals(22, addon.db.profile.font_size)
        assert.equals("THICKOUTLINE", addon.db.profile.font_outline)
        assert.is_true(verticalPosition.disabled())
        assert.is_true(fontOptions.font.disabled())
        assert.is_true(fontOptions.fontSize.disabled())
        assert.is_true(fontOptions.fontOutline.disabled())

        local transfer = env.options.args.importExport.args
        assert.equals("BuffTimers:2:export1", transfer.exportString.get())
        transfer.selectExport.func()
        assert.equals(0, env.selectionDelay)
        assert.is_nil(env.exportFocused)

        -- AceConfig redraws execute controls before the deferred selection runs.
        env.visibleExportText = transfer.exportString.get()
        assert.equals("BuffTimers:2:export2", env.visibleExportText)
        env.selectionCallback()

        assert.is_true(env.exportFocused)
        assert.is_true(env.exportHighlighted)
        assert.is_nil(env.restrictedClipboardCalled)
        assert.is_truthy(transfer.status.name():find("Ctrl+C", 1, true))

        transfer.importString.set(nil, "BuffTimers:2:import")
        assert.is_false(transfer.importProfile.disabled())
        assert.is_function(transfer.importProfile.confirm)
        assert.is_false(transfer.importProfile.confirm())
        env.willReplaceProfile = true
        assert.is_true(transfer.importProfile.confirm())
        assert.equals("BuffTimers:2:import", env.confirmedText)
        assert.equals(
            "A profile with this name already exists and will be replaced. Continue?",
            transfer.importProfile.confirmText
        )
        transfer.importProfile.func()
        assert.equals("BuffTimers:2:import", env.importedText)
        assert.equals("", transfer.importString.get())
        assert.equals(1, env.notifyCount)
    end)
end)
