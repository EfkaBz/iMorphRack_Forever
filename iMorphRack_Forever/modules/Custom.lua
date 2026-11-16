-- iMorph Rack (Forever) : onglet Commandes perso
local _, ns = ...
local L, UI, S = ns.L, ns.UI, ns.Skin
local Button, EditBox, Label, Heading = UI.Button, UI.EditBox, UI.Label, UI.Heading

local ROW_H = 30

local function BuildCustomPage(p)
    local customRows = {}
    local editing -- index de la commande en cours de modification
    local RefreshCustom

    Heading(p, L["New command"], 0, 0)
    Label(p, L["Name"], 12, "muted"):SetPoint("TOPLEFT", 0, -38)
    local name = EditBox(p, 220, L["e.g. Night elf druid"])
    name:SetPoint("TOPLEFT", 110, -33)

    Label(p, L["Command(s)"], 12, "muted"):SetPoint("TOPLEFT", 0, -68)
    local cmd = EditBox(p, 440, ".race 4; .gender 1; .item 5 2522")
    cmd:SetPoint("TOPLEFT", 110, -63)
    cmd:SetMaxLetters(1000)

    Label(p, L["Several commands: separate with ;   e.g. .race 4; .gender 1; .item 5 2522"], 11, "muted")
        :SetPoint("TOPLEFT", 110, -92)

    local add
    local function stopEditing()
        editing = nil
        add:SetText(L["Add"])
        name:SetText(""); cmd:SetText(""); name:ClearFocus(); cmd:ClearFocus()
    end
    local function save()
        local n, c = strtrim(name:GetText()), strtrim(cmd:GetText())
        if n == "" or c == "" then return end
        local ok, word = ns.IsAllowed(c)
        if not ok then
            print("|cffff5555iMorph Rack|r : " .. L["Command not allowed"] .. " (" .. word .. ").")
            return
        end
        if editing and ns.db.custom[editing] then
            ns.db.custom[editing] = { name = n, cmd = c }
        else
            table.insert(ns.db.custom, { name = n, cmd = c })
        end
        stopEditing()
        RefreshCustom()
    end
    cmd:SetScript("OnEnterPressed", save)
    name:SetScript("OnEnterPressed", function() cmd:SetFocus() end)
    add = Button(p, L["Add"], 110, 24, save, true)
    add:SetPoint("TOPRIGHT", 0, -62)
    Button(p, L["Test"], 110, 24, function() ns.Run(cmd:GetText()) end):SetPoint("TOPRIGHT", 0, -32)

    Heading(p, L["My commands"], 0, -122)

    local box = UI.ListBox(p)
    box:SetPoint("TOPLEFT", 0, -150)
    box:SetPoint("BOTTOMRIGHT", 0, 0)

    local scroll, child = S.Scroll(box)
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -16, 6)
    local rowW = UI.PAGE_W - 22
    child:SetWidth(rowW)

    local empty = S.Text(box, 13, "muted")
    empty:SetPoint("CENTER")
    empty:SetText(L["No custom commands yet."])

    RefreshCustom = function()
        for _, r in ipairs(customRows) do r:Hide() end
        for i, entry in ipairs(ns.db.custom) do
            local r = customRows[i]
            if not r then
                r = CreateFrame("Frame", nil, child)
                r:SetSize(rowW, ROW_H)
                r:EnableMouse(true)
                r:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(self.entry.name)
                    GameTooltip:AddLine(self.entry.cmd, 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                r:SetScript("OnLeave", GameTooltip_Hide)
                S.RowHighlight(r)
                r.bg = r:CreateTexture(nil, "BACKGROUND")
                r.bg:SetAllPoints()
                r.text = S.Text(r, 13, "gold")
                r.text:SetPoint("LEFT", 10, 0)
                r.text:SetWidth(180)
                r.text:SetWordWrap(false)
                r.cmd = S.Text(r, 11, "muted")
                r.cmd:SetPoint("LEFT", 198, 0)
                r.cmd:SetWidth(rowW - 198 - 230)
                r.cmd:SetWordWrap(false)
                r.run = Button(r, L["Apply"], 84, 22, nil, true)
                r.run:SetPoint("RIGHT", -112, 0)
                r.edit = Button(r, L["Edit"], 74, 22)
                r.edit:SetPoint("RIGHT", -34, 0)
                r.del = Button(r, "x", 26, 22)
                r.del:SetPoint("RIGHT", -4, 0)
                customRows[i] = r
            end
            r.entry = entry
            r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
            r.bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.025 or 0)
            r.text:SetText(entry.name)
            r.cmd:SetText(entry.cmd)
            r.run:SetScript("OnClick", function() ns.Run(entry.cmd) end)
            r.edit:SetScript("OnClick", function()
                editing = i
                name:SetText(entry.name)
                cmd:SetText(entry.cmd)
                add:SetText(L["Save"])
                cmd:SetFocus()
            end)
            r.del:SetScript("OnClick", function()
                UI.Confirm(format(L["Delete \"%s\"?"], entry.name), function()
                    for k, e in ipairs(ns.db.custom) do
                        if e == entry then table.remove(ns.db.custom, k) break end
                    end
                    if editing then stopEditing() end
                    RefreshCustom()
                end)
            end)
            r:SetAlpha(1)
            r:Show()
        end
        child:SetHeight(math.max(1, #ns.db.custom * ROW_H))
        empty:SetShown(#ns.db.custom == 0)
    end
    p:SetScript("OnShow", RefreshCustom)
    RefreshCustom()
end

ns.RegisterPage({ key = "perso", label = "Custom", icon = "INV_Misc_Note_01", build = BuildCustomPage })
