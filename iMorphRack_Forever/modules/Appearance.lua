-- iMorph Rack (Forever) : onglet Apparence
local _, ns = ...
local L, UI = ns.L, ns.UI
local Button, EditBox, Label, Heading, CommandRow = UI.Button, UI.EditBox, UI.Label, UI.Heading, UI.CommandRow
local W, COL2 = UI.WIDTH, UI.COL2

local function BuildAppearancePage(p)
    Heading(p, L["Model"], 0, 0)
    Heading(p, L["Character"], COL2, 0)
    local left, right = 0, 0
    for i, a in ipairs(ns.APPEARANCE) do
        if i <= 5 then
            left = left + 1
            CommandRow(p, 0, -6 - left * 32, L[a.label], function(v) return a.cmd .. " " .. v end)
        else
            right = right + 1
            CommandRow(p, COL2, -6 - right * 32, L[a.label], function(v) return a.cmd .. " " .. v end)
        end
    end
    Button(p, L["Dismount (.mount 0)"], 200, 24, function() ns.Run(".mount 0") end):SetPoint("TOPLEFT", 0, -220)

    Heading(p, L["Pet"], 0, -262)
    CommandRow(p, 0, -294, L["Pet morph (display ID)"], function(v) return ".morphpet " .. v end)
    Heading(p, L["Shapeshift forms"], COL2, -262)
    CommandRow(p, COL2, -294, L["Form ID + display ID"], function(v) return ".shapeshift " .. v end)
    Label(p, L["e.g. 1 892 = cat form in display 892"], "GameFontNormalSmall"):SetPoint("TOPLEFT", COL2, -322)
end

ns.RegisterPage({ key = "look", label = "Appearance", icon = "INV_Misc_Head_Human_01", build = BuildAppearancePage })
