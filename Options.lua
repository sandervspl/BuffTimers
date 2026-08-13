local BuffTimers = LibStub("AceAddon-3.0"):GetAddon("BuffTimers")
local module = BuffTimers:NewModule("Config")
local L = LibStub("AceLocale-3.0"):GetLocale("BuffTimers")
BuffTimersLibSharedMedia = LibStub("LibSharedMedia-3.0", true)
local db
local exportText = ""
local importText = ""
local transferStatus

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local importErrors = {
    EMPTY = "Paste a profile string first.",
    TOO_LONG = "The profile string is too long.",
    INVALID_FORMAT = "This is not a BuffTimers profile string.",
    INVALID_DATA = "The profile string is damaged or incomplete.",
    INVALID_PROFILE = "The profile data is invalid.",
}

local function SetTransferStatus(message, isError, notify)
    local color = isError and "ffff4040" or "ff40ff40"
    transferStatus = "|c" .. color .. message .. "|r"
    if notify ~= false then
        AceConfigRegistry:NotifyChange("BuffTimers")
    end
end

local function SelectExportString()
    if exportText == "" then
        return false
    end

    -- AceConfig creates this option with AceGUI's bundled MultiLineEditBox widget.
    -- Clipboard writes are protected, so select the text for the user's normal copy shortcut.
    for index = 1, AceGUI:GetWidgetCount("MultiLineEditBox") do
        local editBox = _G["MultiLineEditBox" .. index .. "Edit"]
        if editBox and editBox:IsVisible() and editBox:GetText() == exportText then
            editBox:SetFocus()
            editBox:HighlightText()
            return true
        end
    end

    return false
end

local function GetImportError(errorCode, detail)
    if errorCode == "UNSUPPORTED_VERSION" then
        return L["This profile string uses an unsupported version (%s)."]:format(detail or "?")
    elseif errorCode == "INVALID_VALUE" then
        return L["The profile contains an invalid value for %s."]:format(detail or "?")
    end

    return L[importErrors[errorCode] or "The profile data is invalid."]
end

local function IsTextCustomizationDisabled()
    return not db.profile.customize_text
end

function module:OnInitialize()
    db = BuffTimers.db

    local options = {
        type = "group",
        name = "BuffTimers",
        args = {
            time = {
                type = "group",
                name = L["Time"],
                order = 10,
                args = {
                    formatGroup = {
                        type = "group",
                        name = L["Format"],
                        inline = true,
                        args = {
                            timeFormat = {
                                type = "select",
                                name = L["Time Stamp Format"],
                                desc = L["Choose the format for displaying buff duration"],
                                values = {
                                    ["m"] = "minutes (119m)",
                                    ["hm"] = "h:mm (1:59h)",
                                },
                                get = function() return db.profile.time_stamp end,
                                set = function(_, value) db.profile.time_stamp = value end,
                                order = 1,
                            },
                        },
                    },
                    secondsThresholdGroup = {
                        type = "group",
                        name = L["Seconds"],
                        inline = true,
                        args = {
                            showSeconds = {
                                type = "toggle",
                                name = L["Show seconds"],
                                desc = L["Show seconds for buff timers"],
                                get = function() return db.profile.seconds end,
                                set = function(_, value) db.profile.seconds = value end,
                                order = 2,
                            },
                            secondsThreshold = {
                                type = "range",
                                name = L["Show seconds below this time"],
                                desc = L["Only show seconds when buffs have less than this many minutes"],
                                width = "full",
                                min = 1,
                                max = 120,
                                step = 1,
                                get = function() return db.profile.seconds_threshold end,
                                set = function(_, value) db.profile.seconds_threshold = value end,
                                order = 3,
                            },
                            showMilliseconds = {
                                type = "toggle",
                                name = L["Show milliseconds below 5 seconds"],
                                desc = L["Show milliseconds for buff timers with less than 5 seconds remaining"],
                                width = "full",
                                get = function() return db.profile.milliseconds end,
                                set = function(_, value) db.profile.milliseconds = value end,
                                order = 4,
                            },
                        }
                    }
                }
            },
            textGroup = {
                type = "group",
                name = L["Text"],
                order = 15,
                args = {
                    colorGroup = {  
                        type = "group",
                        name = L["Color"],
                        inline = true,
                        args = {
                            yellowText = {
                                type = "toggle",
                                name = L["Always yellow text color"],
                                desc = L["Always use yellow for buff timer text"],
                                get = function() return db.profile.yellow_text end,
                                set = function(_, value) db.profile.yellow_text = value end,
                                width = "full",
                                order = 1,
                            },
                            coloredText = {
                                type = "toggle",
                                name = L["Add more colors to the timer"],
                                desc = L["Use different colors based on remaining time"],
                                get = function() return db.profile.colored_text end,
                                set = function(_, value) db.profile.colored_text = value end,
                                width = "full",
                                order = 2,
                            },
                        }
                    },
                    customizeTextGroup = {
                        type = "group",
                        name = L["Customization"],
                        inline = true,
                        args = {
                            enableCustomizeText = {
                                type = "toggle",
                                name = L["Enable"],
                                desc = L["Enable text customization"],
                                get = function() return db.profile.customize_text end,
                                set = function(_, value) BuffTimers:SetTextCustomizationEnabled(value) end,
                                width = "full",
                                order = 7,
                            },
                            verticalPosition = {
                                type = "range",
                                name = L["Text vertical position"],
                                desc = L["Adjust the vertical position of the timer text"],
                                min = BuffTimers.VERTICAL_POSITION_MIN,
                                max = BuffTimers.VERTICAL_POSITION_MAX,
                                step = 1,
                                get = function() return db.profile.vertical_position end,
                                set = function(_, value) db.profile.vertical_position = value end,
                                disabled = IsTextCustomizationDisabled,
                                order = 8,
                            },
                            fontGroup = {
                                type = "group",
                                name = L["Font"],
                                inline = true,
                                args = {
                                    font = {
                                        type = "select",
                                        name = L["Font"],
                                        desc = L["Choose the font for the timer text"],
                                        values = function()
                                            local fonts = BuffTimersLibSharedMedia:List("font")
                                            local values = {}
                                            for _, font in ipairs(fonts) do
                                                values[font] = font
                                            end
                                            return values
                                        end,
                                        get = function() return db.profile.font end,
                                        set = function(_, value) db.profile.font = value end,
                                        disabled = IsTextCustomizationDisabled,
                                        order = 1,
                                    },
                                    fontSize = {
                                        type = "range",
                                        name = L["Font Size"],
                                        desc = L["Adjust the font size of the timer text"],
                                        min = 1,
                                        max = 100,
                                        step = 1,
                                        get = function() return db.profile.font_size end,
                                        set = function(_, value) db.profile.font_size = value end,
                                        disabled = IsTextCustomizationDisabled,
                                        order = 2,
                                    },
                                    fontOutline = {
                                        type = "select",
                                        name = L["Outline"],
                                        desc = L["Choose the outline for the timer text"],
                                        values = {
                                            [""] = "None",
                                            ["OUTLINE"] = "Outline",
                                            ["THICKOUTLINE"] = "Thick",
                                            ["MONOCHROME"] = "Monochrome",
                                        },
                                        get = function() return db.profile.font_outline end,
                                        set = function(_, value) db.profile.font_outline = value end,
                                        disabled = IsTextCustomizationDisabled,
                                        order = 3,
                                    }
                                }
                            }
                        }
                    }
                },
            },
            importExport = {
                type = "group",
                name = L["Import / Export"],
                desc = L["Share or restore the currently active profile."],
                order = 30,
                args = {
                    description = {
                        type = "description",
                        name = L["Share or restore the currently active profile."],
                        order = 1,
                    },
                    exportString = {
                        type = "input",
                        name = L["Export string"],
                        desc = L["Click the field and press Ctrl+A, then Ctrl+C to copy the active profile."],
                        multiline = 8,
                        width = "full",
                        get = function()
                            exportText = BuffTimers:ExportProfile()
                            return exportText
                        end,
                        set = function() end,
                        order = 2,
                    },
                    selectExport = {
                        type = "execute",
                        name = L["Select for copying"],
                        desc = L["Select the export string, then press Ctrl+C to copy it."],
                        func = function()
                            SetTransferStatus(L["Export string selected. Press Ctrl+C to copy it."], false, false)

                            -- AceConfig redraws after execute controls run. Select on the next frame so
                            -- the newly-created export edit box keeps focus and its selection.
                            C_Timer.After(0, function()
                                if not SelectExportString() then
                                    SetTransferStatus(
                                        L["Could not select the export string. Click the field and press Ctrl+A, then Ctrl+C."],
                                        true
                                    )
                                end
                            end)
                        end,
                        order = 3,
                    },
                    importString = {
                        type = "input",
                        name = L["Import string"],
                        desc = L["Paste a BuffTimers profile string here."],
                        multiline = 8,
                        width = "full",
                        get = function() return importText end,
                        set = function(_, value)
                            importText = value
                            transferStatus = nil
                        end,
                        order = 4,
                    },
                    importProfile = {
                        type = "execute",
                        name = L["Import profile"],
                        confirm = function()
                            return BuffTimers:WillImportReplaceProfile(importText)
                        end,
                        confirmText = L["A profile with this name already exists and will be replaced. Continue?"],
                        disabled = function() return importText:match("^%s*$") ~= nil end,
                        func = function()
                            local success, errorCode, detail = BuffTimers:ImportProfile(importText)
                            if success then
                                importText = ""
                                SetTransferStatus(L["The profile was imported successfully."], false)
                            else
                                SetTransferStatus(GetImportError(errorCode, detail), true)
                            end
                        end,
                        order = 5,
                    },
                    status = {
                        type = "description",
                        name = function() return transferStatus or "" end,
                        order = 6,
                    },
                },
            },
        },
    }

    local profileOptions = AceDBOptions:GetOptionsTable(db)
    profileOptions.order = 20
    options.args.profiles = profileOptions

    -- Register the options with AceConfig
    AceConfigRegistry:RegisterOptionsTable("BuffTimers", options)
    
    -- Create the options panel
    AceConfigDialog:AddToBlizOptions("BuffTimers", "BuffTimers")
end

function module:ShowConfig()
	AceConfigDialog:Open("BuffTimers")
end

SLASH_BUFFTIMERS1 = "/bufftimers"
function SlashCmdList.BUFFTIMERS()
	module:ShowConfig()
end
