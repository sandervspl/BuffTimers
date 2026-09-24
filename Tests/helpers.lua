local Helpers = {}

local unpackValues = unpack or table.unpack

Helpers.supportedClients = {
    { name = "Retail", interface = 120100, branch = "live" },
    { name = "Mists of Pandaria Classic", interface = 50504, branch = "classic" },
    { name = "Titan", interface = 38002, branch = "classic_titan" },
    { name = "Anniversary", interface = 20506, branch = "classic_anniversary" },
    { name = "Classic Era", interface = 11509, branch = "classic_era" },
    { name = "Forever", interface = 16001, branch = "forever" },
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
        font = { "Fonts\\FRIZQT__.TTF", 10 },
        fontObject = "GameFontNormalSmall",
        hideCount = 0,
        points = {},
        showCount = 0,
    }

    function duration:SetTextColor(...)
        self.color = { ... }
        table.insert(self.colorCalls, self.color)
    end

    function duration:SetPoint(...)
        self.point = { ... }
        table.insert(self.points, self.point)
    end

    function duration:GetNumPoints()
        return #self.points
    end

    function duration:GetPoint(index)
        return unpackValues(self.points[index])
    end

    function duration:ClearAllPoints()
        self.point = nil
        self.points = {}
        self.clearAllPointsCount = (self.clearAllPointsCount or 0) + 1
    end

    function duration:SetFont(...)
        self.font = { ... }
    end

    function duration:GetFont()
        return unpackValues(self.font)
    end

    function duration:GetFontObject()
        return self.fontObject
    end

    function duration:SetFontObject(fontObject)
        self.fontObject = fontObject
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

    env.profileSetRequests = {}

    local function newDatabase(profile, profileName)
        local database = {
            currentProfile = profileName,
            profile = profile,
            profiles = {
                [profileName] = profile,
            },
        }

        function database:GetCurrentProfile()
            return self.currentProfile
        end

        function database:GetProfiles(destination)
            destination = destination or {}
            for key in pairs(destination) do
                destination[key] = nil
            end

            local count = 0
            for name in pairs(self.profiles) do
                count = count + 1
                destination[count] = name
            end
            if not self.profiles[self.currentProfile] then
                count = count + 1
                destination[count] = self.currentProfile
            end

            return destination, count
        end

        function database:SetProfile(name)
            table.insert(env.profileSetRequests, name)
            self.currentProfile = name
            self.profile = self.profiles[name] or Helpers.defaultProfile()
            self.profiles[name] = self.profile
        end

        function database:ResetProfile()
            env.profileResetCount = (env.profileResetCount or 0) + 1
            self.profile = Helpers.defaultProfile()
            self.profiles[self.currentProfile] = self.profile
        end

        return database
    end

    addon.db = newDatabase(Helpers.defaultProfile(options.profile), options.profileName or "Default")

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
        local profileName = defaultProfile == true and "Default" or defaultProfile or "Character"
        env.database = newDatabase(defaults.profile, profileName)
        return env.database
    end

    local serializer = {}
    function serializer:Serialize(value)
        env.serializeRequest = value
        if options.serialize then
            return options.serialize(value)
        end
        return "^1mock^^"
    end
    function serializer:Deserialize(value)
        env.deserializeRequest = value
        if options.deserialize then
            return options.deserialize(value)
        end
        return false, "invalid mock serialization"
    end

    local libraries = {
        ["AceAddon-3.0"] = aceAddon,
        ["AceLocale-3.0"] = aceLocale,
        ["AceDB-3.0"] = aceDB,
        ["AceSerializer-3.0"] = serializer,
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
    _G.issecretvalue = options.issecretvalue
    _G.BuffTimersOptions = options.oldOptions
    _G.BuffTimersDB = nil
    _G.SMALLER_AURA_DURATION_FONT_MIN_THRESHOLD = options.smallerAuraDurationFont and 3600 or nil

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
