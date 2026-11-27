-- iMorph Rack (Forever) : onglet Apparence
local _, ns = ...
local L, UI, S = ns.L, ns.UI, ns.Skin
local Button, Label, Heading, CommandRow = UI.Button, UI.Label, UI.Heading, UI.CommandRow
local COL2 = UI.COL2

-- menu des options : les plus courantes d'abord, puis toutes celles connues d'iMorph
local function CustomizationOptions()
    local t, seen = {}, {}
    for _, o in ipairs(ns.CUSTOMIZATION_COMMON) do
        t[#t + 1] = { o[1], L[o[2]], L[o[2]] .. "  |cff8a96a8." .. o[1] .. "|r" }
        seen[o[1]] = true
    end
    local rest = {}
    for _, n in ipairs(ns.CustomizationNames()) do
        if not seen[n] then rest[#rest + 1] = n end
    end
    table.sort(rest)
    for _, n in ipairs(rest) do t[#t + 1] = { n, "." .. n } end
    return t
end

-- dernière valeur envoyée pour une option (look actuel)
local function LastValue(name)
    local look = ns.CharDB().look
    local v = (look.cust and look.cust[name]) or look[name]
    return tonumber(v) or 0
end

local function BuildCustomization(p, x, y)
    local current = "skincolor"

    Label(p, L["Option"], 12):SetPoint("TOPLEFT", x, y)
    local value
    local dd = S.Dropdown(p, 188, 230, CustomizationOptions, function() return current end, function(v)
        current = v
        value:SetText(tostring(LastValue(v)))
    end, { maxRows = 14 })
    dd:SetPoint("TOPLEFT", x + 142, y + 5)

    Label(p, L["Choice"], 12):SetPoint("TOPLEFT", x, y - 32)
    local function send(v)
        v = math.max(0, math.floor(tonumber(v) or 0))
        value:SetText(tostring(v))
        value:ClearFocus()
        ns.Run("." .. current .. " " .. v)
    end
    local prev = Button(p, "<", 26, 22, function() send((tonumber(value:GetText()) or 0) - 1) end)
    prev:SetPoint("TOPLEFT", x + 142, y - 27)
    value = UI.EditBox(p, 50)
    value:SetPoint("LEFT", prev, "RIGHT", 6, 0)
    value:SetNumeric(true)
    value:SetJustifyH("CENTER")
    value:SetText(tostring(LastValue(current)))
    value:SetScript("OnEnterPressed", function(self) send(self:GetText()) end)
    local nextB = Button(p, ">", 26, 22, function() send((tonumber(value:GetText()) or 0) + 1) end)
    nextB:SetPoint("LEFT", value, "RIGHT", 6, 0)
    UI.Tooltip(prev, L["Previous choice"])
    UI.Tooltip(nextB, L["Next choice"])

    local list = Button(p, L["Options of my race"], 188, 22, function() ns.Run(".customization") end)
    list:SetPoint("TOPLEFT", x + 142, y - 60)
    UI.Tooltip(list, L["Options of my race"], L["Asks iMorph for the options available for the race you are displaying."])

    local note = Label(p, L["Options depend on the displayed race: iMorph answers \"invalid\" if the race does not have it."], 11, "muted")
    note:SetPoint("TOPLEFT", x, y - 92)
    note:SetWidth(UI.PAGE_W - x)
    note:SetJustifyH("LEFT")

    p:HookScript("OnShow", function() value:SetText(tostring(LastValue(current))) end)
end

local function BuildAppearancePage(p)
    Heading(p, L["Model"], 0, 0, COL2 - 24)
    for i, a in ipairs(ns.APPEARANCE) do
        CommandRow(p, 0, -6 - i * 32, L[a.label], function(v) return a.cmd .. " " .. v end)
    end
    Button(p, L["Dismount (.mount 0)"], 200, 24, function() ns.Run(".mount 0") end):SetPoint("TOPLEFT", 0, -214)

    Heading(p, L["Character"], COL2, 0)
    BuildCustomization(p, COL2, -38)

    Heading(p, L["Pet"], 0, -262, COL2 - 24)
    CommandRow(p, 0, -300, L["Pet morph (display ID)"], function(v) return ".morphpet " .. v end)
    Heading(p, L["Shapeshift forms"], COL2, -262)
    CommandRow(p, COL2, -300, L["Form ID + display ID"], function(v) return ".shapeshift " .. v end)
    Label(p, L["e.g. 1 892 = cat form in display 892"], 11, "muted"):SetPoint("TOPLEFT", COL2, -326)
end

ns.RegisterPage({ key = "look", label = "Appearance", icon = "INV_Misc_Head_Human_01", build = BuildAppearancePage })
