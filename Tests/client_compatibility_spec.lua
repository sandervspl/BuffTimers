local Helpers = dofile("Tests/helpers.lua")

local function readSupportedInterfaces()
    local toc = assert(io.open("BuffTimers.toc", "r"))
    local contents = toc:read("*a")
    toc:close()

    local interfaceLine = assert(contents:match("## Interface:%s*([^\r\n]+)"))
    local interfaces = {}

    for interface in interfaceLine:gmatch("%d+") do
        table.insert(interfaces, tonumber(interface))
    end

    return interfaces
end

describe("supported WoW clients", function()
    it("keeps the test matrix synchronized with BuffTimers.toc", function()
        local expected = {}

        for _, client in ipairs(Helpers.supportedClients) do
            table.insert(expected, client.interface)
        end

        assert.same(expected, readSupportedInterfaces())
    end)

    for _, client in ipairs(Helpers.supportedClients) do
        local clientCase = client
        local testName = clientCase.name ..
            " (" .. clientCase.interface .. ", " .. clientCase.branch .. ") handles every modern aura shape"

        it(testName, function()
            local buffButton = {
                OnUpdate = function() end,
                UpdateDuration = function() end,
            }
            local debuffButton = {
                OnUpdate = function() end,
                UpdateDuration = function() end,
            }
            local env = Helpers.loadAddon({
                modern = true,
                modernFrames = {
                    buffs = { buffButton },
                    debuffs = { debuffButton },
                },
            })

            env.addon:OnEnable()

            assert.equals(2, #env.hooks)
            assert.same({ buffButton, "UpdateDuration", env.addon.OnAuraDurationUpdate }, env.hooks[1])
            assert.same({ debuffButton, "UpdateDuration", env.addon.OnAuraDurationUpdate }, env.hooks[2])

            local auraCases = {
                {
                    hook = env.hooks[1][3],
                    info = {
                        auraType = "Buff",
                        index = 1,
                        duration = 30,
                        expirationTime = 130,
                        timeMod = 1,
                    },
                },
                {
                    hook = env.hooks[2][3],
                    info = {
                        auraType = "Debuff",
                        index = 1,
                        duration = 30,
                        expirationTime = 130,
                        timeMod = 1,
                    },
                },
                {
                    hook = env.hooks[1][3],
                    info = {
                        auraType = "TempEnchant",
                        expirationTime = 130,
                        ID = 16,
                    },
                },
                {
                    hook = env.hooks[2][3],
                    info = {
                        auraType = "DeadlyDebuff",
                        auraInstanceID = 77,
                        duration = 30,
                        expirationTime = 130,
                        timeMod = 1,
                    },
                },
            }

            for _, auraCase in ipairs(auraCases) do
                local duration = Helpers.newDuration()
                local aura = {
                    Duration = duration,
                    buttonInfo = auraCase.info,
                }

                auraCase.hook(aura, 30)

                assert.equals("30s", duration.text)
                assert.is_true(duration.visible)
            end

            assert.equals(0, #env.timerCallbacks)
            assert.equals(0, #env.auraQueries)
        end)
    end
end)
