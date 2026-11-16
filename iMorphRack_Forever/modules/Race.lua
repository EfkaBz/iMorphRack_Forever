-- iMorph Rack (Forever) : onglet Race / Genre
local _, ns = ...
local L, UI = ns.L, ns.UI
local Button, Heading, CommandRow = UI.Button, UI.Heading, UI.CommandRow
local COL2 = UI.COL2

local function BuildRacePage(p)
    local step = UI.PAGE_W / 4
    local function Grid(list, y)
        for i, r in ipairs(list) do
            local b = Button(p, L[r.name], step - 8, 22, function() ns.Run(".race " .. r.id) end)
            b:SetPoint("TOPLEFT", ((i - 1) % 4) * step, y - math.floor((i - 1) / 4) * 26)
            UI.Tooltip(b, L[r.name], ".race " .. r.id)
        end
        return y - math.ceil(#list / 4) * 26
    end
    Heading(p, L["Classic races"], 0, 0)
    local y = Grid(ns.RACES, -30)
    Heading(p, L["Other races (depends on the client)"], 0, y - 10)
    y = Grid(ns.EXTRA_RACES, y - 40)

    y = y - 14
    Heading(p, L["Gender"], 0, y, COL2 - 24)
    Button(p, L["Male"], 120, 24, function() ns.Run(".gender 0") end):SetPoint("TOPLEFT", 0, y - 32)
    Button(p, L["Female"], 120, 24, function() ns.Run(".gender 1") end):SetPoint("TOPLEFT", 128, y - 32)
    Heading(p, L["Race by ID"], COL2, y)
    CommandRow(p, COL2, y - 36, L["Race ID"], function(v) return ".race " .. v end)

    local reset = Button(p, L["Reset everything (.reset)"], 250, 26, function() ns.Run(".reset") end)
    reset:SetPoint("BOTTOMLEFT", 0, 0)
end

ns.RegisterPage({ key = "race", label = "Race / Gender", icon = "Spell_Shadow_Charm", build = BuildRacePage })
