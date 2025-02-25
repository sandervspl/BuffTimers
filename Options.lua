local BuffTimers = LibStub("AceAddon-3.0"):GetAddon("BuffTimers")
local module = BuffTimers:NewModule("Config")
local L = LibStub("AceLocale-3.0"):GetLocale("BuffTimers")
local db

function module:OnInitialize()
    db = BuffTimers.db

    local options = {
        type = "group",
        name = "BuffTimers",
        args = {
            generalSettings = {
                type = "group",
                name = "BuffTimers",
                inline = true,
                order = 1,
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
                        get = function() return db.profile.milliseconds end,
                        set = function(_, value) db.profile.milliseconds = value end,
                        order = 4,
                    },
                    yellowText = {
                        type = "toggle",
                        name = L["Always yellow text color"],
                        desc = L["Always use yellow for buff timer text"],
                        get = function() return db.profile.yellow_text end,
                        set = function(_, value) db.profile.yellow_text = value end,
                        order = 5,
                    },
                    coloredText = {
                        type = "toggle",
                        name = L["Add more colors to the timer"],
                        desc = L["Use different colors based on remaining time"],
                        get = function() return db.profile.colored_text end,
                        set = function(_, value) db.profile.colored_text = value end,
                        order = 6,
                    },
                    customizeText = {
                        type = "toggle",
                        name = L["Customize text"],
                        desc = L["Enable text customization"],
                        get = function() return db.profile.customize_text end,
                        set = function(_, value) db.profile.customize_text = value end,
                        order = 7,
                    },
                    verticalPosition = {
                        type = "range",
                        name = L["Text vertical position"],
                        desc = L["Adjust the vertical position of the timer text"],
                        min = -100,
                        max = 100,
                        step = 1,
                        get = function() return db.profile.vertical_position end,
                        set = function(_, value) db.profile.vertical_position = value end,
                        order = 8,
                    },
                    fontSize = {
                        type = "range",
                        name = L["Text font size"],
                        desc = L["Adjust the font size of the timer text"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function() return db.profile.font_size end,
                        set = function(_, value) db.profile.font_size = value end,
                        order = 9,
                    },
                },
            },
        },
    }

    -- Register the options with AceConfig
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("BuffTimers", options)
    
    -- Create the options panel
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BuffTimers", "BuffTimers")
end

function module:ShowConfig()
	LibStub("AceConfigDialog-3.0"):Open("BuffTimers")
end

SLASH_BUFFTIMERS1 = "/bufftimers"
SLASH_BUFFTIMERS2 = "/bt"
function SlashCmdList.BUFFTIMERS()
	module:ShowConfig()
end