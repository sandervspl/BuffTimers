local Helpers = {}

local unpackValues = unpack or table.unpack

Helpers.supportedClients = {
    { name = "Retail", interface = 120100, branch = "live" },
    { name = "Mists of Pandaria Classic", interface = 50504, branch = "classic" },
    { name = "Titan", interface = 38002, branch = "classic_titan" },
    { name = "Anniversary", interface = 20506, branch = "classic_anniversary" },
    { name = "Classic Era", interface = 11509, branch = "classic_era" },
}

function Helpers.defaultProfile(overrides)
    local profile = {
        time_stamp = "m",
        seconds = false,
        seconds_threshold = 30,
        milliseconds = true,
        yellow_text = false,
        colored_text = false,
        customize_text = false,
        vertical_position = -34,
        font = "Friz Quadrata TT",
        font_size = 14,
        font_outline = "",
    }

    for key, value in pairs(overrides or {}) do
        profile[key] = value
    end

    return profile
end

function Helpers.newDuration()
    local duration = {
        colorCalls = {},
        hideCount = 0,
        showCount = 0,
    }

    function duration:SetTextColor(...)
        self.color = { ... }
        table.insert(self.colorCalls, self.color)
    end

    function duration:SetPoint(...)
        self.point = { ... }
    end

    function duration:SetFont(...)
        self.font = { ... }
    end

    function duration:SetText(text)
        self.text = text
    end

    function duration:Show()
        self.visible = true
        self.showCount = self.showCount + 1
    end

    function duration:Hide()
        self.visible = false
        self.hideCount = self.hideCount + 1
    end

    return duration
end

function Helpers.loadAddon(options)
    options = options or {}

    local env = {
        auraQueries = {},
        hooks = {},
        mediaQueries = {},
        timerCallbacks = {},
        unitAuraQueries = {},
    }
    local addon = {}
    local namespace = {}

    addon.db = {
        profile = Helpers.defaultProfile(options.profile),
    }

    local aceAddon = {}
    function aceAddon:GetAddon(name)
        if name ~= "BuffTimers" then
            error("unexpected addon lookup: " .. tostring(name))
        end
        return addon
    end

    local aceLocale = {}
    function aceLocale:GetLocale(name)
        if name ~= "BuffTimers" then
            error("unexpected locale lookup: " .. tostring(name))
        end
        return {}
    end

    local aceDB = {}
    function aceDB:New(name, defaults, defaultProfile)
        env.dbRequest = {
            name = name,
            defaults = defaults,
            defaultProfile = defaultProfile,
        }
        env.database = { profile = defaults.profile }
        return env.database
    end

    local libraries = {
        ["AceAddon-3.0"] = aceAddon,
        ["AceLocale-3.0"] = aceLocale,
        ["AceDB-3.0"] = aceDB,
    }

    _G.LibStub = function(name)
        local library = libraries[name]
        if not library then
            error("unexpected library lookup: " .. tostring(name))
        end
        return library
    end

    _G.floor = math.floor
    _G.ceil = math.ceil
    _G.BuffTimersOptions = options.oldOptions
    _G.BuffTimersDB = nil

    local modernFrames = options.modernFrames or {}
    if options.modern == false then
        _G.BuffFrame = {}
        _G.DebuffFrame = {}
    else
        _G.BuffFrame = { auraFrames = modernFrames.buffs or {} }
        _G.DebuffFrame = { auraFrames = modernFrames.debuffs or {} }
    end

    _G.hooksecurefunc = function(...)
        table.insert(env.hooks, { ... })
    end

    _G.C_Timer = {
        After = function(delay, callback)
            table.insert(env.timerCallbacks, {
                delay = delay,
                callback = callback,
            })
            if options.runTimersImmediately ~= false then
                callback()
            end
        end,
    }

    _G.C_UnitAuras = {
        GetAuraDataByAuraInstanceID = function(unit, auraInstanceID)
            table.insert(env.auraQueries, {
                unit = unit,
                auraInstanceID = auraInstanceID,
            })
            return env.auraData
        end,
    }

    _G.GetTime = function()
        return env.now or options.now or 100
    end

    _G.getglobal = function(name)
        return _G[name]
    end

    _G.UnitAura = function(...)
        table.insert(env.unitAuraQueries, { ... })
        local result = env.unitAuraResult
        if result then
            return unpackValues(result, 1, result.n or #result)
        end
    end

    _G.BuffTimersLibSharedMedia = {
        Fetch = function(_, mediaType, name)
            table.insert(env.mediaQueries, {
                mediaType = mediaType,
                name = name,
            })
            return options.fontPath or "Fonts\\Mock.ttf"
        end,
    }

    local chunk, loadError = loadfile("BuffTimers.lua")
    if not chunk then
        error(loadError)
    end
    chunk("BuffTimers", namespace)

    env.addon = addon
    env.namespace = namespace
    return env
end

return Helpers
