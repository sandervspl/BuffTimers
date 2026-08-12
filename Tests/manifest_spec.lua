local function readFile(path)
    local file = assert(io.open(path, "r"))
    local contents = file:read("*a")
    file:close()
    return contents
end

describe("addon manifest", function()
    it("loads embedded libraries in an unpackaged checkout", function()
        local embeds = readFile("embeds.xml")
        local requiredEntries = {
            '<Script file="libs\\LibStub\\LibStub.lua"/>',
            '<Include file="libs\\CallbackHandler-1.0\\CallbackHandler-1.0.xml"/>',
            '<Include file="libs\\AceAddon-3.0\\AceAddon-3.0.xml"/>',
            '<Script file="libs\\AceLocale-3.0\\AceLocale-3.0.lua"/>',
            '<Include file="libs\\AceDB-3.0\\AceDB-3.0.xml"/>',
            '<Include file="libs\\AceConfig-3.0\\AceConfig-3.0.xml"/>',
            '<Include file="libs\\LibSharedMedia-3.0\\lib.xml"/>',
        }

        assert.is_nil(embeds:find("<!--@non-debug@", 1, true))
        assert.is_nil(embeds:find("@end-non-debug@-->", 1, true))

        for _, entry in ipairs(requiredEntries) do
            assert.is_truthy(embeds:find(entry, 1, true), "missing active embed entry: " .. entry)
        end
    end)

    it("loads embeds before addon runtime files", function()
        local toc = readFile("BuffTimers.toc")
        local embedsPosition = assert(toc:find("embeds.xml", 1, true))
        local localesPosition = assert(toc:find("Locales.lua", 1, true))
        local corePosition = assert(toc:find("BuffTimers.lua", 1, true))
        local optionsPosition = assert(toc:find("Options.lua", 1, true))

        assert.is_true(embedsPosition < localesPosition)
        assert.is_true(embedsPosition < corePosition)
        assert.is_true(embedsPosition < optionsPosition)
    end)
end)
