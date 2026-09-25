local Helpers = dofile("Tests/helpers.lua")

-- Failure cases: secret arithmetic/conversion, secret aura identifiers, and
-- clients without the native string API. The native mock models only its text
-- transformation; the successful in-game check is recorded separately.
describe("secret aura duration formatting", function()
    local env, oldStringUtil, secretValues

    before_each(function()
        oldStringUtil = C_StringUtil
        secretValues = {}
        env = Helpers.loadAddon({ issecretvalue = function(value) return secretValues[value] ~= nil end })
        _G.C_StringUtil = {
            RemoveContiguousSpaces = function(text, count)
                assert.equals(0, count)
                return (text:gsub(" ", ""))
            end,
        }
    end)

    after_each(function()
        _G.C_StringUtil = oldStringUtil
    end)

    local function render(time, secretID)
        local secret = setmetatable({}, {
            __add = function() error("secret arithmetic") end,
            __sub = function() error("secret arithmetic") end,
            __div = function() error("secret arithmetic") end,
            __mod = function() error("secret arithmetic") end,
            __lt = function() error("secret comparison") end,
            __tostring = function() error("secret conversion") end,
        })
        secretValues[secret] = time
        local duration = Helpers.newDuration()
        duration.text = "5 m"
        function duration:GetText() return self.text end
        duration:Show()
        env.addon.OnAuraDurationUpdate({ Duration = duration, unit = "player",
            buttonInfo = { auraInstanceID = secretID and secret or 77 } }, secret)
        return duration
    end

    it("leaves Blizzard's text intact if the native string API is unavailable", function()
        _G.C_StringUtil = nil
        assert.equals("5 m", render(243.66).text)
    end)

    it("uses compact native text if the aura identifier is secret", function()
        assert.equals("5m", render(243.66, true).text)
    end)

end)
