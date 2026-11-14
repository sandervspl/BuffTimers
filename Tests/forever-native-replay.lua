-- Run once per client in a fresh Lua VM, setting BUFFTIMERS_TEST_INTERFACE to
-- 120105 (Retail) or 16001 (Forever). Defaults to Forever for the standalone CLI.
-- lua Tests/forever-native-replay.lua
-- Replays addon configuration and lifecycle, not WoW's secret/taint engine.
-- Failure scenarios: accidental other-client activation, duplicate legacy art,
-- combat access to adopted objects, lost settings, hide/show, and failed setup.
local function check(value, message)
    assert(value, message)
    print("PASS " .. message)
end

for _, interface in ipairs({ 50504, 38002, 20506, 11509 }) do
    function GetBuildInfo() return nil, nil, nil, interface end
    function LibStub() error("native module ran on a different client") end
    dofile("NativeAuras.lua")
end
check(true, "all other supported clients return before accessing addon/native APIs")

local combat, showDurations, editing, expanded, gamepad = false, true, false, true, false
local modules, ticker, root, messages = {}, nil, nil, {}
local containers = {}
local profile = { time_stamp = "m", seconds = false, seconds_threshold = 30, detailed_time_on_hover = false,
    milliseconds = true, customize_text = true, font = "test", font_size = 10,
    font_outline = "", vertical_position = -42 }
function GetBuildInfo() return nil, nil, nil, BUFFTIMERS_TEST_INTERFACE or 16001 end
function InCombatLockdown() return combat end
function CopyTable(value)
    local copy = {}
    for key, item in pairs(value) do copy[key] = type(item) == "table" and CopyTable(item) or item end
    return copy
end
local addon = { db = { profile = profile } }
function addon:NewModule(name) local module = {}; modules[name] = module; return module end
function addon:GetModule(name) return modules[name] end
function addon:SetTextCustomizationEnabled(value) self.db.profile.customize_text = value end
local uiOptions
local locale = setmetatable({}, { __index = function(_, key) return key end })
local libraries = {
    ["AceAddon-3.0"] = { GetAddon = function() return addon end },
    ["AceLocale-3.0"] = { GetLocale = function() return locale end },
    ["AceConfigRegistry-3.0"] = {
        RegisterOptionsTable = function(_, _, options) uiOptions = options end,
        NotifyChange = function() end,
    },
    ["AceConfigDialog-3.0"] = { AddToBlizOptions = function() end },
    ["AceDBOptions-3.0"] = { GetOptionsTable = function() return { args = {} } end },
    ["AceGUI-3.0"] = {},
}
function LibStub(name)
    if name == "LibSharedMedia-3.0" then return BuffTimersLibSharedMedia end
    return assert(libraries[name], name)
end
local originalPrint = print
function print(message) messages[#messages + 1] = message; originalPrint(message) end
function hooksecurefunc(object, name, callback)
    local original = object[name]
    object[name] = function(...) original(...); callback(...) end
end
SlashCmdList = {}
C_Timer = { NewTicker = function(_, callback) ticker = callback; return { Cancel = function() end } end }
InputUtil = { IsGamepadUIEnabled = function() return gamepad end }
CVarCallbackRegistry = { GetCVarValueBool = function() return showDurations end }
BuffTimersLibSharedMedia = { Fetch = function(_, _, name) return name .. ".ttf" end }
GameFontNormalSmall = "native-font"
Enum = { NumericRuleFormatRounding = { Down = 0, Up = 1 }, LuaCurveType = { Step = 0 },
    DurationTextBindingProperty = { RemainingDuration = 0 } }
AnchorUtil = { FlowLayoutAxis = { Horizontal = 0, Vertical = 1 },
    FlowDirection = { Left = 0, Right = 1, Up = 2, Down = 3 } }
AuraContainerSortMethod = { AuraInstanceIDOnly = 8 }
AuraContainerItemEnchantmentSlot = { MainHand = 0, OffHand = 1, Ranged = 2 }
function CreateColor(...) return { ... } end
C_CurveUtil = { CreateColorCurve = function()
    return {
        points = {}, SetType = function() end,
        AddPoint = function(self, x, color) self.points[#self.points + 1] = { x, color } end,
        Evaluate = function(self, x)
            local color
            for _, point in ipairs(self.points) do if x >= point[1] then color = point[2] end end
            return color
        end,
    }
end }

local failFormatter = false
C_StringUtil = { CreateNumericRuleFormatter = function()
    return {
        SetBreakpoints = function(self, rules) self.rules = rules end,
        FormatNumber = function(self, value)
            if failFormatter then return "wrong" end
            local rule
            for _, candidate in ipairs(self.rules) do
                if value >= candidate.threshold then rule = candidate end
            end
            local function round(number, step, direction)
                if not step then return number end
                local n = number / step
                return (direction == Enum.NumericRuleFormatRounding.Up and math.ceil(n) or math.floor(n)) * step
            end
            value = round(value, rule.step, rule.rounding)
            if not rule.components then return string.format(rule.format, value) end
            local args = {}
            for _, component in ipairs(rule.components) do
                local v = value / (component.div or 1)
                if component.mod then v = v % component.mod end
                args[#args + 1] = round(v, component.step, component.rounding)
            end
            return string.format(rule.format, unpack(args))
        end,
    }
end }

local function region(restricted)
    local object = { alpha = 1, mouse = true }
    local function write(self, key, ...)
        assert(not (restricted and combat), "accessed adopted native object in combat")
        self[key] = { ... }
    end
    function object:SetAlpha(alpha) self.alpha = alpha end
    function object:EnableMouse(enabled) self.mouse = enabled end
    for _, method in ipairs({ "SetSize", "SetPoint", "SetFont", "SetFontObject", "SetDrawLayer", "SetTexture", "SetAllPoints", "SetColorTexture" }) do
        object[method] = function(self, ...) write(self, method .. "Args", ...) end
    end
    function object:ClearAllPoints() write(self, "SetPointArgs") end
    function object:Show() write(self, "shown", true) end
    function object:Hide() write(self, "shown", false) end
    function object:SetShown(value) write(self, "shown", value) end
    function object:CreateTexture(_, layer)
        local texture = region(restricted)
        texture.layer = layer
        self.textures = self.textures or {}
        self.textures[#self.textures + 1] = texture
        return texture
    end
    function object:CreateFontString(_, layer)
        local text = region(restricted)
        text.layer = layer
        return text
    end
    function object:SetIcon(icon) self.icon = icon end
    function object:SetApplicationCount(count) self.count = count end
    function object:SetCancelAuraButtons(buttons) self.cancel = buttons end
    function object:SetDurationText(text, options) write(self, "duration", text, options) end
    function object:ClearDurationText() write(self, "duration") end
    return object
end

local legacy, private = region(false), region(false)
private.isAuraAnchor = true
BuffFrame = {
    auraFrames = { legacy, private }, maxAuras = 32,
    AuraContainer = { isHorizontal = true, addIconsToRight = false, addIconsToTop = false,
        iconStride = 8, iconPadding = 5, iconScale = 1 },
    IsEditing = function() return editing end,
    IsExpanded = function() return expanded end,
    SetSize = function(self, width, height) self.size = { width, height } end,
    UpdateSize = function() end,
}
function CreateFrame(frameType, _, parent)
    check(frameType == "AuraContainer" and parent == BuffFrame, "container belongs to existing buff host")
    local container = region(false)
    if not root then root = container end
    containers[#containers + 1] = container
    local root = container
    root.children = {}
    function root:SetEnabled(value) self.enabled = value end
    function root:SetEditModePreviewEnabled() end
    function root:SetUnit(value) self.unit = value end
    function root:GetFrameLevel() return 1 end
    function root:SetFrameLevel(value) self.level = value end
    function root:AddAuraGroup(_, filter, options)
        self.filter, self.options = filter, options
        for _ = 1, 2 do
            local child = region(true)
            self.children[#self.children + 1] = child
            options.initializeFrame(child)
        end
    end
    function root:AddItemEnchantment(_, options)
        local child = region(true)
        self.children[#self.children + 1] = child
        options.initializeFrame(child)
    end
    for _, method in ipairs({ "SetScale", "SetFlowLayoutAnchorPoint", "SetFlowLayoutAxis", "SetFlowLayoutGrowthDirection",
        "SetAuraGroupLayout", "SetItemEnchantmentLayout", "SetFlowLayoutMaximumLineSize" }) do
        root[method] = function(self, ...) self[method .. "Args"] = { ... } end
    end
    return root
end

dofile("NativeAuras.lua")
dofile("Options.lua")
modules.Config:OnInitialize()
modules.NativeAuras:OnEnable()
local nativeGroup = uiOptions.args.time.args.nativeTimers
local toggle = nativeGroup.args.enabled
check(not nativeGroup.hidden() and not toggle.disabled() and toggle.get(), "options expose enabled native timers on supported clients")
check(nativeGroup.args.status.hidden() and nativeGroup.args.status.name() == "", "active renderer has no redundant status text")
check(not SlashCmdList.BUFFTIMERSNATIVE and not SLASH_BUFFTIMERSNATIVE1, "native slash command is removed")
check(root and root.enabled and BuffTimersNativeDB.enabled, "native mode starts enabled without a saved preference")
check(root.enabled and root.filter == "HELPFUL" and root.unit == "player", "enabling delegates real player buffs to native container")
check(legacy.alpha == 0 and not legacy.mouse and private.alpha == 1, "only original buff buttons are suppressed")
check(BuffFrame.size[2] == 225, "fixed host capacity reserves room for full buffs plus all weapon enchants")
local secret = setmetatable({}, { __tostring = function() error("secret conversion") end })
legacy:SetAlpha(secret)
check(legacy.alpha == 0, "native warning-flash updates cannot reveal duplicate original art")
local child = root.children[1]
local timerText = child.duration[1]
local nativeFormatter = child.duration[2].textFormatter
check(nativeFormatter:FormatNumber(86400) == "1d" and nativeFormatter:FormatNumber(61) == "2m"
    and nativeFormatter:FormatNumber(4.9) == "4.9s", "native rules cover days, ceil minutes and suffixed tenths")
check(child.SetSizeArgs[1] == 30 and child.SetFontArgs == nil and child.duration[1].SetFontArgs[2] == 10,
    "buff dimensions and configured timer font are applied")
profile.detailed_time_on_hover = true
ticker()
local hoverRoot = containers[2]
check(root.enabled and hoverRoot.enabled and nativeGroup.args.status.hidden(),
    "enabling detailed hover keeps the replacement renderer active")
local hoverChild = hoverRoot.children[1]
local hoverText = hoverChild.duration[1]
local hoverFormatter = hoverChild.duration[2].textFormatter
check(hoverText.SetDrawLayerArgs[1] == "HIGHLIGHT" and not hoverChild.icon and not hoverChild.count,
    "hover overlay has engine-controlled highlight text without duplicate icons or stacks")
check(hoverChild.cancel == nil and child.cancel == "RightButtonUp",
    "only the main native button can cancel a buff")
local plate = hoverChild.textures[2]
check(plate.layer == "HIGHLIGHT" and plate.SetAllPointsArgs[1] == hoverText,
    "hover-only backplate follows the detailed label without reading its secret width")
check(hoverRoot.options.sortMethod == root.options.sortMethod
    and hoverRoot.SetPointArgs[1] == root.SetPointArgs[1] and hoverRoot.level == 2,
    "native containers use identical assignment ordering and aligned layout")
-- Model the engine's draw-layer selection. Addon code never receives either the
-- remaining time or the mouseover flag, and defines no hover script/query API.
local function display(base, hover, seconds, mouseover)
    local detailed = hover.duration[2].textFormatter:FormatNumber(seconds)
    if mouseover and detailed ~= "" then return detailed end
    return base.duration[2].textFormatter:FormatNumber(seconds)
end
for _, sample in ipairs({ { 6300, "01:45:00" }, { 3600, "01:00:00" }, { 3599.9, "59:59" },
    { 60, "01:00" }, { 59, "59s" }, { 4.9, "4.9s" } }) do
    check(display(child, hoverChild, sample[1], true) == sample[2], "hover sample " .. sample[1])
end
check(display(child, hoverChild, 6300, false) == "105m", "leaving hover reveals the live compact timer")
check(display(child, hoverChild, 7200, true) == "02:00:00"
    and display(root.children[2], hoverRoot.children[2], 300, false) == "5m",
    "a refreshed hovered buff changes immediately while another buff keeps compact text")
combat = true
profile.font_size = 18
ticker()
check(toggle.disabled(), "native options toggle is disabled in combat")
toggle.set(nil, false)
check(root.enabled and hoverRoot.enabled and BuffTimersNativeDB.enabled and child.duration[1].SetFontArgs[2] == 10,
    "combat ticks and commands defer configuration without touching adopted objects")
legacy:SetAlpha(secret)
check(legacy.alpha == 0, "original art stays suppressed during combat")
combat = false
ticker()
check(child.duration[1].SetFontArgs[2] == 18, "profile changes apply after combat")
check(hoverChild.duration[1].SetFontArgs[2] == 18, "hover label follows the updated timer font")
showDurations = false
ticker()
check(not child.duration[1] and timerText.shown[1] == false, "duration CVar clears native bindings and hides text")
check(not hoverRoot.enabled and not hoverChild.duration[1], "duration CVar disables hover bindings too")
showDurations = true
ticker()
check(child.duration[1] ~= nil, "duration CVar restores native binding")
BuffFrame.AuraContainer.isHorizontal = false
BuffFrame.AuraContainer.addIconsToRight = true
BuffFrame.AuraContainer.addIconsToTop = true
BuffFrame.AuraContainer.iconStride = 3
BuffFrame.AuraContainer.iconScale = 1.5
ticker()
check(child.SetSizeArgs[1] == 60 and root.SetFlowLayoutMaximumLineSizeArgs[1] == 100
    and root.SetFlowLayoutAnchorPointArgs[1] == "BOTTOMLEFT" and root.SetScaleArgs[1] == 1.5,
    "vertical growth, stride and scale follow existing layout settings")
check(hoverRoot.SetFlowLayoutAnchorPointArgs[1] == "BOTTOMLEFT" and hoverRoot.SetScaleArgs[1] == 1.5,
    "hover overlay follows vertical layout and scale")
profile.detailed_time_on_hover = false
ticker()
check(root.enabled and not hoverRoot.enabled, "disabling detailed hover keeps compact native timers active")
profile.detailed_time_on_hover = true
ticker()
check(hoverRoot.enabled and #containers == 2, "re-enabling hover reuses its native container")
local formats = uiOptions.args.time.args.formatGroup.args
local secondsOptions = uiOptions.args.time.args.secondsThresholdGroup.args
local formatCases = {
    { "m", false, 30, false, { { 4.99, "4s" }, { 59.9, "59s" }, { 61, "2m" },
        { 3599, "60m" }, { 6300, "105m" }, { 86399, "1440m" }, { 86400, "1d" }, { 86401, "1d" }, { 90000, "2d" } } },
    { "m", true, 30, true, { { 4.99, "4.9s" }, { 60, "1:00" }, { 61, "1:01" },
        { 1799.9, "29:59" }, { 1800, "30m" } } },
    { "m", true, 120, true, { { 6299, "104:59" }, { 6300, "105:00" }, { 7199, "119:59" }, { 7200, "120m" } } },
    { "hm", false, 30, true, { { 3599, "60m" }, { 3600, "1:00h" }, { 3600.1, "1:01h" },
        { 3659, "1:01h" }, { 3660, "1:01h" }, { 6300, "1:45h" }, { 6301, "1:46h" },
        { 7140, "1:59h" }, { 7140.1, "2:00h" }, { 7199, "2:00h" }, { 7200, "2:00h" },
        { 86399, "24:00h" }, { 86400, "1d" } } },
    { "hm", true, 120, true, { { 3599, "59:59" }, { 3600, "1:00:00" }, { 3659, "1:00:59" },
        { 6300, "1:45:00" }, { 7199, "1:59:59" }, { 7200, "2:00h" } } },
    { "hm", true, 60, false, { { 4.99, "4s" }, { 3599, "59:59" }, { 3600, "1:00h" } } },
    { "hm", true, 1, false, { { 59, "59s" }, { 60, "1m" }, { 61, "2m" }, { 3600, "1:00h" } } },
}
for _, case in ipairs(formatCases) do
    formats.timeFormat.set(nil, case[1])
    secondsOptions.showSeconds.set(nil, case[2])
    secondsOptions.secondsThreshold.set(nil, case[3])
    secondsOptions.showMilliseconds.set(nil, case[4])
    ticker()
    check(root.enabled and hoverRoot.enabled, "formatting options keep both native renderers active")
    local formatter = child.duration[2].textFormatter
    for _, sample in ipairs(case[5]) do
        check(formatter:FormatNumber(sample[1]) == sample[2],
            case[1] .. " seconds=" .. tostring(case[2]) .. " threshold=" .. case[3] .. ": " .. sample[1] .. " = " .. sample[2])
    end
    check(display(child, hoverChild, 6300, true) == "01:45:00", "detailed hover works with each format/seconds configuration")
end

-- Drive the remaining display options through their actual menu callbacks.
local colors = uiOptions.args.textGroup.args.colorGroup.args
colors.coloredText.set(nil, true)
ticker()
local curve = child.duration[2].textColor.curve
check(curve:Evaluate(59)[1] == 1 and curve:Evaluate(59)[2] == 0.1
    and curve:Evaluate(60)[2] > 0.8 and curve:Evaluate(600)[2] == 1,
    "colored timers select red, yellow and green bands natively")
check(colors.coloredText.desc() == "Use different colors based on remaining time",
    "color option describes native thresholds without the legacy-only restriction")
colors.yellowText.set(nil, true)
ticker()
curve = child.duration[2].textColor.curve
check(curve:Evaluate(0)[2] > 0.8 and curve:Evaluate(600)[1] > 0.99,
    "always-yellow overrides colored thresholds")
colors.coloredText.set(nil, false)
colors.yellowText.set(nil, false)
ticker()
check(child.duration[2].textColor.curve:Evaluate(59)[2] == 1,
    "disabling color overrides restores native white short timers")
local customization = uiOptions.args.textGroup.args.customizeTextGroup.args
customization.enableCustomizeText.set(nil, false)
ticker()
check(child.duration[1].SetFontObjectArgs[1] == GameFontNormalSmall
    and hoverChild.duration[1].SetFontObjectArgs[1] == GameFontNormalSmall,
    "disabling text customization restores both native font objects")
customization.enableCustomizeText.set(nil, true)
customization.verticalPosition.set(nil, -65)
local fonts = customization.fontGroup.args
fonts.font.set(nil, "alternate-font")
fonts.fontSize.set(nil, 22)
for _, outline in ipairs({ "", "OUTLINE", "THICKOUTLINE", "MONOCHROME" }) do
    fonts.fontOutline.set(nil, outline)
    ticker()
    local font = hoverChild.duration[1].SetFontArgs
    check(font[1] == "alternate-font.ttf" and font[2] == 22 and font[3] == (outline ~= "" and outline or nil)
        and hoverChild.duration[1].SetPointArgs[5] == -65,
        "font, size, vertical position and outline option " .. (outline ~= "" and outline or "None") .. " reach native hover text")
end
local savedProfile = profile
addon.db.profile = CopyTable(profile)
addon.db.profile.time_stamp = "m"
addon.db.profile.seconds = false
ticker()
check(root.enabled and toggle.get() and child.duration[2].textFormatter:FormatNumber(6300) == "105m",
    "switching profile tables updates formatting without changing the renderer preference")
addon.db.profile = savedProfile
combat = true
formats.timeFormat.set(nil, "hm")
secondsOptions.showSeconds.set(nil, true)
secondsOptions.secondsThreshold.set(nil, 120)
ticker()
check(root.enabled and child.duration[2].textFormatter:FormatNumber(6300) == "105m",
    "profile changes during combat leave the current native binding running")
combat = false
ticker()
check(child.duration[2].textFormatter:FormatNumber(6300) == "1:45:00", "format changes apply after combat")
gamepad = true
ticker()
check(not root.enabled and legacy.alpha == 1 and legacy.mouse, "unsupported gamepad navigation restores original rendering and input")
check(colors.coloredText.desc():find("Blizzard's colors", 1, true), "color option explains restrictions while the legacy renderer is active")
gamepad = false
ticker()
check(root.enabled and legacy.alpha == 0, "mouse/keyboard navigation reactivates existing native container")
editing = true
ticker()
check(not root.enabled and legacy.alpha == 1, "Edit Mode restores Blizzard previews")
editing = false
ticker()
expanded = false
ticker()
check(not root.enabled and legacy.alpha == 1, "collapsed view uses original rendering")
expanded = true
ticker()
toggle.set(nil, false)
check(not toggle.get() and nativeGroup.args.status.hidden() and nativeGroup.args.status.name() == "",
    "options toggle persists disabled state without redundant status text")
check(not root.enabled and legacy.alpha == 1 and legacy.mouse, "explicit opt-out restores originals")
check(BuffFrame.size[1] == 1072.5, "opt-out restores legacy host capacity for the active layout")
failFormatter = true
toggle.set(nil, true)
check(not root.enabled and not BuffTimersNativeDB.enabled and legacy.alpha == 1,
    "failed native formatter self-check disables mode without hiding original buffs")
failFormatter = false
dofile("NativeAuras.lua")
modules.NativeAuras:OnEnable()
check(not BuffTimersNativeDB.enabled and not root.enabled and legacy.alpha == 1,
    "a saved disabled preference remains disabled after addon initialization")
-- A supported interface number is not enough if a client lacks required APIs.
C_StringUtil.CreateNumericRuleFormatter = nil
ticker = nil
BuffTimersNativeDB.enabled = true
dofile("NativeAuras.lua")
modules.NativeAuras:OnEnable()
check(toggle.disabled() and not nativeGroup.args.status.hidden() and nativeGroup.args.status.name():find("unavailable", 1, true),
    "options disable native control and explain missing APIs")
toggle.set(nil, true)
check(not ticker and not root.enabled and legacy.alpha == 1 and legacy.mouse,
    "missing native APIs leave original rendering and input untouched")
modules.NativeAuras = nil
check(nativeGroup.hidden(), "native options are hidden when the client has no native renderer module")
originalPrint("PASS native lifecycle replay; combat renderer still requires in-game verification")
