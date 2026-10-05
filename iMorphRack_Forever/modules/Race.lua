-- iMorph Rack (Forever) : onglet Race / Genre
local _, ns = ...
local L, UI = ns.L, ns.UI
local Button, EditBox, Label, Heading, CommandRow = UI.Button, UI.EditBox, UI.Label, UI.Heading, UI.CommandRow
local W, COL2 = UI.WIDTH, UI.COL2

local function BuildRacePage(p)
    local function Grid(list, y)
        for i, r in ipairs(list) do
            local b = Button(p, L[r.name], 158, 22, function() ns.Run(".race " .. r.id) end)
            b:SetPoint("TOPLEFT", ((i - 1) % 4) * 165, y - math.floor((i - 1) / 4) * 26)
            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(".race " .. r.id)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", GameTooltip_Hide)
        end
        return y - math.ceil(#list / 4) * 26
    end
    Heading(p, L["Classic races"], 0, 0)
    local y = Grid(ns.RACES, -26)
    Heading(p, L["Other races (depends on the client)"], 0, y - 8)
    y = Grid(ns.EXTRA_RACES, y - 34)

    y = y - 12
    Heading(p, L["Gender"], 0, y)
    Button(p, L["Male"], 120, 22, function() ns.Run(".gender 0") end):SetPoint("TOPLEFT", 0, y - 26)
    Button(p, L["Female"], 120, 22, function() ns.Run(".gender 1") end):SetPoint("TOPLEFT", 128, y - 26)
    Heading(p, L["Race by ID"], COL2, y)
    CommandRow(p, COL2, y - 30, L["Race ID"], function(v) return ".race " .. v end)

    Button(p, L["Reset everything (.reset)"], 250, 24, function() ns.Run(".reset") end):SetPoint("BOTTOMLEFT", 0, 0)
end

ns.RegisterPage({ key = "race", label = "Race / Gender", icon = "Spell_Shadow_Charm", build = BuildRacePage })
