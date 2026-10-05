-- iMorph Rack (Forever) : onglet Objets
local _, ns = ...
local L, UI = ns.L, ns.UI
local Button, EditBox, Label, Heading, CommandRow = UI.Button, UI.EditBox, UI.Label, UI.Heading, UI.CommandRow
local W, COL2 = UI.WIDTH, UI.COL2

local function BuildItemsPage(p)
    Heading(p, L["Armor"], 0, 0)
    Heading(p, L["Weapons and misc"], COL2, 0)
    local boxes = {}
    local half = math.ceil(#ns.SLOTS / 2)
    for i, s in ipairs(ns.SLOTS) do
        local x = i <= half and 0 or COL2
        local row = i <= half and i or i - half
        boxes[s.id] = CommandRow(p, x, -6 - row * 30, L[s.name], function(v) return ".item " .. s.id .. " " .. v end)
        boxes[s.id]:SetNumeric(true)
        if ns.pendingItems[s.id] then boxes[s.id]:SetText(ns.pendingItems[s.id]) end
    end
    ns.itemBoxes = boxes
    local y = -6 - (half + 1) * 30
    Heading(p, L["Weapon enchants"], 0, y)
    CommandRow(p, 0, y - 30, L["Main hand"], function(v) return ".enchant 1 " .. v end)
    CommandRow(p, COL2, y - 30, L["Off hand"], function(v) return ".enchant 2 " .. v end)

    Button(p, L["Fill with my gear"], 220, 24, function()
        for id, e in pairs(boxes) do
            local item = GetInventoryItemID("player", id)
            e:SetText(item and tostring(item) or "")
        end
    end):SetPoint("BOTTOMLEFT", 0, 0)
    Button(p, L["Apply all"], 180, 24, function()
        for _, s in ipairs(ns.SLOTS) do
            local v = strtrim(boxes[s.id]:GetText())
            if v ~= "" then ns.Run(".item " .. s.id .. " " .. v) end
        end
    end):SetPoint("BOTTOMRIGHT", 0, 0)
end

ns.RegisterPage({ key = "items", label = "Items", icon = "INV_Chest_Plate06", build = BuildItemsPage })
