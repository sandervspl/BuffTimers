local function readFile(path)
    local file = assert(io.open(path, "r"))
    local contents = file:read("*a")
    file:close()
    return contents
end

describe("bundled Ace3 compatibility", function()
    it("includes the Retail tooltip alpha fix", function()
        local path = "libs/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua"
        local source = readFile(path)
        local _, fixedCallCount = source:gsub(
            "tooltip:SetText%(name, 1, %.82, 0, 1, true%)",
            ""
        )

        assert.is_nil(source:find("tooltip:SetText(name, 1, .82, 0, true)", 1, true))
        assert.equals(2, fixedCallCount)
        assert.is_truthy(source:find('local MAJOR, MINOR = "AceConfigDialog-3.0", 92', 1, true))
    end)
end)
