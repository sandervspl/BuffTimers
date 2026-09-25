local addonName, addon = ...
local BuffTimers = LibStub("AceAddon-3.0"):GetAddon("BuffTimers")
local L = LibStub("AceLocale-3.0"):GetLocale("BuffTimers")
local Serializer = LibStub("AceSerializer-3.0")

local PROFILE_EXPORT_VERSION = 2
local LEGACY_PROFILE_EXPORT_VERSION = 1
local PROFILE_EXPORT_PREFIX = "BuffTimers:" .. PROFILE_EXPORT_VERSION .. ":"
local PROFILE_EXPORT_MAX_LENGTH = 10000
local VERTICAL_POSITION_MIN = -100
local VERTICAL_POSITION_MAX = 0
local DEFAULT_TEXT_VERTICAL_POSITION = -34
local DEFAULT_TEXT_FONT = "Friz Quadrata TT"
local DEFAULT_TEXT_FONT_SIZE = 14
local DEFAULT_TEXT_FONT_OUTLINE = ""
BuffTimers.VERTICAL_POSITION_MIN = VERTICAL_POSITION_MIN
BuffTimers.VERTICAL_POSITION_MAX = VERTICAL_POSITION_MAX
local PROFILE_KEYS = {
    "time_stamp",
    "seconds",
    "seconds_threshold",
    "milliseconds",
    "yellow_text",
    "colored_text",
    "customize_text",
    "vertical_position",
    "font",
    "font_size",
    "font_outline",
}
local BOOLEAN_PROFILE_KEYS = {
    "seconds",
    "milliseconds",
    "yellow_text",
    "colored_text",
    "customize_text",
}

-- Retail and Forever use the modern buff frame, and after its UI modernization Classic Era
-- does too. Detect it directly -- BuffFrame.auraFrames replaced the old AuraButton_Update
-- global we hook below, and project ID alone does not identify the frame implementation.
local isNotClassic = BuffFrame.auraFrames ~= nil
addon.isNotClassic = isNotClassic

-- Keep Blizzard's resolved font object, anchors, and draw layer for each duration region while it is
-- customized. These values can vary by locale and by the modern aura-frame layout.
local nativeDurationStyles = setmetatable({}, { __mode = "k" })

local function CaptureNativeDurationStyle(duration)
    local fontFile, fontHeight, fontFlags = duration:GetFont()
    local drawLayer, drawSublevel = duration:GetDrawLayer()
    local style = {
        fontFile = fontFile,
        fontHeight = fontHeight,
        fontFlags = fontFlags,
        fontObject = duration:GetFontObject(),
        drawLayer = drawLayer,
        drawSublevel = drawSublevel,
        points = {},
    }

    for index = 1, duration:GetNumPoints() do
        local point, relativeTo, relativePoint, offsetX, offsetY = duration:GetPoint(index)
        style.points[index] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            offsetX = offsetX,
            offsetY = offsetY,
        }
    end

    nativeDurationStyles[duration] = style
end

local function RestoreNativeDurationStyle(duration)
    local style = nativeDurationStyles[duration]
    if not style then
        return
    end

    duration:ClearAllPoints()
    for _, anchor in ipairs(style.points) do
        duration:SetPoint(
            anchor.point,
            anchor.relativeTo,
            anchor.relativePoint,
            anchor.offsetX,
            anchor.offsetY
        )
    end
    if style.fontFile then
        local fontFlags = style.fontFlags ~= "" and style.fontFlags or nil
        duration:SetFont(style.fontFile, style.fontHeight, fontFlags)
    end
    duration:SetFontObject(style.fontObject)
    duration:SetDrawLayer(style.drawLayer, style.drawSublevel)

    nativeDurationStyles[duration] = nil
end

local function ApplyDurationTextStyle(self, aura, duration)
    if not self.db.profile.customize_text then
        RestoreNativeDurationStyle(duration)
        return
    end

    if not nativeDurationStyles[duration] then
        CaptureNativeDurationStyle(duration)
    end

    -- Blizzard puts duration text in BACKGROUND and weapon-enchant borders in OVERLAY.
    -- Custom positioning can overlap the border, so draw the text above it.
    duration:SetDrawLayer("OVERLAY", 1)

    local verticalPosition = self.db.profile.vertical_position

    if isNotClassic and verticalPosition == -40 then
        verticalPosition = -39.9
    end

    duration:ClearAllPoints()
    duration:SetPoint("BOTTOM", aura, "TOP", 0, verticalPosition)

    local fontPath = BuffTimersLibSharedMedia:Fetch("font", self.db.profile.font)
    -- "" (None) must be passed as nil, and the old "THICK" preset isn't a real font
    -- flag ("THICKOUTLINE" is); the modern client's SetFont rejects both, so normalize.
    local outline = self.db.profile.font_outline
    if outline == "THICK" then outline = "THICKOUTLINE" end
    duration:SetFont(fontPath, self.db.profile.font_size, outline ~= "" and outline or nil)
end

function BuffTimers:SetTextCustomizationEnabled(enabled)
    self.db.profile.customize_text = enabled

    if enabled then
        return
    end

    local duration = next(nativeDurationStyles)
    while duration do
        RestoreNativeDurationStyle(duration)
        duration = next(nativeDurationStyles)
    end
end

local function GetMilliseconds(time)
    return floor((time % 60) % 1 * 10)
end

local function GetMinutes(time)
    if time then
        return floor(time / 60)
    end
    return 0
end

function BuffTimers:OnInitialize()
    if not BuffTimersOptions then
        BuffTimersOptions = {}
    end

    -- Default configuration
    -- Transfer from old config or use hardcoded default values
    local defaults = {
        profile = {
            time_stamp = BuffTimersOptions["time_stamp"] or "m",
            seconds = BuffTimersOptions["seconds"] or false,
            seconds_threshold = BuffTimersOptions["seconds_threshold"] or 30,
            milliseconds = BuffTimersOptions["milliseconds"] or true,
            yellow_text = BuffTimersOptions["yellow_text"] or false,
            colored_text = BuffTimersOptions["colored_text"] or false,
            customize_text = BuffTimersOptions["customize_text"] or false,
            vertical_position = BuffTimersOptions["vertical_position"] or DEFAULT_TEXT_VERTICAL_POSITION,
            font = DEFAULT_TEXT_FONT,
            font_size = BuffTimersOptions["font_size"] or DEFAULT_TEXT_FONT_SIZE,
            font_outline = DEFAULT_TEXT_FONT_OUTLINE,
        }
    }

    -- Initialize the addon
    self.db = LibStub("AceDB-3.0"):New("BuffTimersDB", defaults, true)
end

local function IsIntegerInRange(value, minimum, maximum)
    return type(value) == "number" and value == floor(value) and value >= minimum and value <= maximum
end

local function ValidateProfileName(profileName)
    if
        type(profileName) ~= "string" or
        #profileName > 200 or
        not profileName:find("%S") or
        profileName:find("[%c]")
    then
        return nil, "INVALID_VALUE", "profile_name"
    end

    return profileName
end

local function ValidateImportedProfile(profile)
    if type(profile) ~= "table" then
        return nil, "INVALID_PROFILE"
    end

    local validated = {}

    if profile.time_stamp ~= "m" and profile.time_stamp ~= "hm" then
        return nil, "INVALID_VALUE", "time_stamp"
    end
    validated.time_stamp = profile.time_stamp

    for _, key in ipairs(BOOLEAN_PROFILE_KEYS) do
        if type(profile[key]) ~= "boolean" then
            return nil, "INVALID_VALUE", key
        end
        validated[key] = profile[key]
    end

    if not IsIntegerInRange(profile.seconds_threshold, 1, 120) then
        return nil, "INVALID_VALUE", "seconds_threshold"
    end
    validated.seconds_threshold = profile.seconds_threshold

    if not IsIntegerInRange(profile.vertical_position, VERTICAL_POSITION_MIN, VERTICAL_POSITION_MAX) then
        return nil, "INVALID_VALUE", "vertical_position"
    end
    validated.vertical_position = profile.vertical_position

    if type(profile.font) ~= "string" or profile.font == "" or #profile.font > 200 then
        return nil, "INVALID_VALUE", "font"
    end
    validated.font = profile.font

    if not IsIntegerInRange(profile.font_size, 1, 100) then
        return nil, "INVALID_VALUE", "font_size"
    end
    validated.font_size = profile.font_size

    local outline = profile.font_outline
    if outline == "THICK" then
        outline = "THICKOUTLINE"
    end
    if outline ~= "" and outline ~= "OUTLINE" and outline ~= "THICKOUTLINE" and outline ~= "MONOCHROME" then
        return nil, "INVALID_VALUE", "font_outline"
    end
    validated.font_outline = outline

    return validated
end

local function DecodeProfileExport(database, exportString)
    if type(exportString) ~= "string" or exportString:match("^%s*$") then
        return false, "EMPTY"
    end
    if #exportString > PROFILE_EXPORT_MAX_LENGTH then
        return false, "TOO_LONG"
    end

    local cleaned = exportString:match("^%s*(.-)%s*$")
    local version = cleaned:match("^BuffTimers:(%d+):")
    if not version then
        return false, "INVALID_FORMAT"
    end
    local versionNumber = tonumber(version)
    if versionNumber ~= PROFILE_EXPORT_VERSION and versionNumber ~= LEGACY_PROFILE_EXPORT_VERSION then
        return false, "UNSUPPORTED_VERSION", version
    end

    local prefix = "BuffTimers:" .. version .. ":"
    local success, payload = Serializer:Deserialize(cleaned:sub(#prefix + 1))
    if not success then
        return false, "INVALID_DATA"
    end

    local profileName
    local profile
    if versionNumber == LEGACY_PROFILE_EXPORT_VERSION then
        -- Version 1 did not include a name, so preserve its original active-profile behavior.
        profileName = database:GetCurrentProfile()
        profile = payload
    elseif type(payload) == "table" then
        profileName = payload.profile_name
        profile = payload.profile
    end

    local validatedName, nameErrorCode, nameField = ValidateProfileName(profileName)
    if not validatedName then
        return false, nameErrorCode, nameField
    end

    local validated, errorCode, field = ValidateImportedProfile(profile)
    if not validated then
        return false, errorCode, field
    end

    return true, validatedName, validated
end

function BuffTimers:ExportProfile()
    local profile = {}

    for _, key in ipairs(PROFILE_KEYS) do
        profile[key] = self.db.profile[key]
    end

    if profile.font_outline == "THICK" then
        profile.font_outline = "THICKOUTLINE"
    end

    return PROFILE_EXPORT_PREFIX .. Serializer:Serialize({
        profile_name = self.db:GetCurrentProfile(),
        profile = profile,
    })
end

function BuffTimers:WillImportReplaceProfile(exportString)
    local success, profileName = DecodeProfileExport(self.db, exportString)
    if not success then
        return false
    end

    local profiles = self.db:GetProfiles()
    for _, existingName in ipairs(profiles) do
        if existingName == profileName then
            return true
        end
    end

    return false
end

function BuffTimers:ImportProfile(exportString)
    local success, profileName, profile = DecodeProfileExport(self.db, exportString)
    if not success then
        return false, profileName, profile
    end

    -- SetProfile creates or selects the exact exported name. Validation happens first, so
    -- malformed imports never switch profiles or change settings.
    self.db:SetProfile(profileName)
    self.db:ResetProfile()
    for key, value in pairs(profile) do
        self.db.profile[key] = value
    end

    return true, profileName
end

function BuffTimers:OnEnable()
    -- Hook the functions when addon is enabled
    if isNotClassic then
        -- Blizzard's OnUpdate already calls UpdateDuration for every timed aura type.
        local frames = { BuffFrame, DebuffFrame }
        for i = 1, #frames do
            for _, button in ipairs(frames[i].auraFrames or {}) do
                if button.UpdateDuration then
                    hooksecurefunc(button, "UpdateDuration", self.OnAuraDurationUpdate)
                end
                -- The zhTW layout adjusts long-duration fonts after UpdateDuration returns.
                -- Reapply only the text style after that adjustment has finished.
                if SMALLER_AURA_DURATION_FONT_MIN_THRESHOLD and button.OnUpdate then
                    hooksecurefunc(button, "OnUpdate", self.OnAuraFrameUpdate)
                end
            end
        end
    else
        hooksecurefunc("AuraButton_Update", self.OnAuraUpdate)
        hooksecurefunc("AuraButton_UpdateDuration", self.OnAuraDurationUpdate)
    end
end

function BuffTimers:FormatTime(time)
    local timeStamp = self.db.profile.time_stamp
    local isSecondsOption = self.db.profile.seconds
    local isMillisecondsOption = self.db.profile.milliseconds
    local showSecondsThreshold = self.db.profile.seconds_threshold
    local seconds = floor(time % 60)
    local minutes = GetMinutes(time)
    local hours = floor(time / 60 / 60)
    local hourMins = ceil(time / 60 % 60) -- This calculates minutes beyond 1 hour
    local days = ceil(hours / 24)
    local milliseconds = 0

    -- Used so we don't accidentally compare numbers with strings
    local str = ""
    local hourMinsStr = hourMins
    local secondsStr = seconds

    local isBelowShowSecThreshold = isSecondsOption and minutes < showSecondsThreshold
    local isBelowShowMillisecThreshold = isMillisecondsOption and minutes < 1 and seconds < 5

    -- If time is more than 24 hours, just render the amount of days
    if hours >= 24 then
        return days .. "d"
    end

     -- Determine if we show time as "h:mm" if not we fall back to minutes
    if
        timeStamp == "hm" and
            ((minutes >= 59 and not isBelowShowSecThreshold) or -- Cases like 1h, 1:01h
                (minutes >= 60 and isBelowShowSecThreshold)) -- Cases like 1:00:59
    then
        -- Display as 2h / 1h etc without minutes
        if hourMins == 60 then
            hours = ceil(time / 60 / 60)
        end

        -- Display floored hour
        if minutes >= 59 then
            str = str .. hours
        end

        -- Determine if we show hourMins
        if
            (minutes >= 60 and hourMins < 60) or -- Cases like 1:01h through 1:59h
                (isBelowShowSecThreshold and minutes >= 59 and hourMins <= 60)
         then -- Cases like 2:00:59
            if isBelowShowSecThreshold then
                -- Determine if we need to show hourMins as a zero (because it ranges between 1 and 60, and 60 == 0)
                if hourMins == 60 then
                    hourMins = 0
                    hourMinsStr = hourMins
                else
                    -- If we show seconds we need to floor the hourMins
                    hourMinsStr = floor(time / 60 % 60)
                end
            end

            -- Determine if we need to prepend hourMins with a zero
            if hourMins < 10 then
                hourMinsStr = 0 .. hourMinsStr
            end

            str = str .. ":" .. hourMinsStr
        end

        -- Determine if we show seconds
        if isBelowShowSecThreshold then
            -- Determine if we need to prepend seconds with a zero
            if seconds < 10 then
                secondsStr = 0 .. secondsStr
            end

            str = str .. ":" .. secondsStr
        end

        -- Determine if we show the "h" affix
        if not isBelowShowSecThreshold then
            str = str .. "h"
        end
    else
        -- Determine if we show seconds
        if isBelowShowSecThreshold then
            if minutes >= 1 then
                -- Add minutes
                str = str .. minutes

                -- Determine if we need to prepend seconds with a zero
                if seconds < 10 then
                    secondsStr = 0 .. secondsStr
                end

                str = str .. ":" .. secondsStr
            else
                -- Only show seconds / ms
                str = seconds

                if isBelowShowMillisecThreshold then
                    milliseconds = GetMilliseconds(time)

                    str = str .. "." .. milliseconds
                end

                str = str .. "s"
            end
        else
            -- If duration is less than an hour and seconds option is not toggled
            if minutes < 1 then
                str = seconds

                if isBelowShowMillisecThreshold then
                    milliseconds = GetMilliseconds(time)

                    str = str .. "." .. milliseconds
                end

                str = str .. "s"
            else
                minutes = ceil(time / 60)
                str = str .. minutes .. "m"
            end
        end
    end

    return str
end

function BuffTimers:SetDurationColor(duration, time)
    -- TBCC introduced a bug (?) where the timer starts ticking down in seconds at 90 seconds instead of 60 seconds
    -- Which also means the time will be white from 90 seconds
    -- This should force the text to be yellow until < 60 seconds
    if time >= 60 then
        duration:SetTextColor(0.99999779462814, 0.81960606575012, 0, 1)
    end

    if self.db.profile.yellow_text then
        duration:SetTextColor(0.99999779462814, 0.81960606575012, 0, 1)
    elseif self.db.profile.colored_text then
        if GetMinutes(time) >= 10 then
            duration:SetTextColor(0.1, 1, 0.1, 1) -- Green
        elseif GetMinutes(time) >= 1 then
            duration:SetTextColor(0.99999779462814, 0.81960606575012, 0, 1) -- Yellow
        else
            duration:SetTextColor(1, 0.1, 0.1, 1) -- Red
        end
    end
end

function BuffTimers.OnAuraDurationUpdate(aura, time)
    local duration = isNotClassic and aura.Duration or aura.duration
    local self = BuffTimers

    if isNotClassic then
        if aura.isExample then
            return
        end
        if CVarCallbackRegistry and not CVarCallbackRegistry:GetCVarValueBool("buffDurations") then
            return
        end
    end

    ApplyDurationTextStyle(self, aura, duration)

    -- This string operation explicitly permits secret arguments from addon code.
    -- Direct numeric formatter/curve evaluation requires untainted execution.
    if issecretvalue and issecretvalue(time) then
        if C_StringUtil and C_StringUtil.RemoveContiguousSpaces then
            duration:SetText(C_StringUtil.RemoveContiguousSpaces(duration:GetText(), 0))
        end
        return
    end

    if time then
        local ok, result = pcall(function()
            return self:FormatTime(time)
        end)

        if ok and result then
            duration:SetText(result)
            self:SetDurationColor(duration, time)
            duration:Show()
        end
    else
        duration:Hide()
    end
end

function BuffTimers.OnAuraFrameUpdate(aura)
    ApplyDurationTextStyle(BuffTimers, aura, aura.Duration)
end

function BuffTimers.OnAuraUpdate(auraSlot, index, filter)
    local auraName = auraSlot .. index
    local auraDuration = getglobal(auraName .. "Duration")

    if not auraDuration then
        return
    end

    local name, _, _, _, _, expirationTime = UnitAura("player", index, filter)

    if name and expirationTime > 0 then
        auraDuration:Show()
    else
        auraDuration:Hide()
    end
end
