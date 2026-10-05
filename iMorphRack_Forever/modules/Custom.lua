-- iMorph Rack (Forever) : onglet Commandes perso
local _, ns = ...
local L, UI = ns.L, ns.UI
local Button, EditBox, Label, Heading, CommandRow = UI.Button, UI.EditBox, UI.Label, UI.Heading, UI.CommandRow
local W, COL2 = UI.WIDTH, UI.COL2
local customRows = {}

local function BuildCustomPage(p)
    Heading(p, L["New command"], 0, 0)
    Label(p, L["Name"]):SetPoint("TOPLEFT", 0, -34)
    local name = EditBox(p, 200)
    name:SetPoint("TOPLEFT", 100, -30)

    Label(p, L["Command(s)"]):SetPoint("TOPLEFT", 0, -62)
    local cmd = EditBox(p, 400)
    cmd:SetPoint("TOPLEFT", 100, -58)
    cmd:SetMaxLetters(1000)

    Label(p, L["Several commands: separate with ;   e.g. .race 4; .gender 1; .item 5 2522"], "GameFontNormalSmall")
        :SetPoint("TOPLEFT", 0, -88)

    local add = function()
        local n, c = strtrim(name:GetText()), strtrim(cmd:GetText())
        if n == "" or c == "" then return end
        local ok, word = ns.IsAllowed(c)
        if not ok then
            print("|cffff5555iMorph Rack|r : " .. L["Command not allowed"] .. " (" .. word .. ").")
            return
        end
        table.insert(ns.db.custom, { name = n, cmd = c })
        name:SetText(""); cmd:SetText(""); name:ClearFocus(); cmd:ClearFocus()
        RefreshCustom()
    end
    cmd:SetScript("OnEnterPressed", add)
    Button(p, L["Add"], 90, 22, add):SetPoint("TOPRIGHT", 0, -58)
    Button(p, L["Test"], 90, 22, function() ns.Run(cmd:GetText()) end):SetPoint("TOPRIGHT", 0, -30)

    Heading(p, L["My commands"], 0, -116)

    -- liste dans un cadre sombre, comme les listes d'Alt Dashboard
    local box = UI.ListBox(p)
    box:SetPoint("TOPLEFT", 0, -140)
    box:SetPoint("BOTTOMRIGHT", 0, 0)

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -28, 6)
    local rowW = W - 60 - 34
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(rowW, 1)
    scroll:SetScrollChild(child)

    local empty = box:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("CENTER")
    empty:SetText(L["No custom commands yet."])

    RefreshCustom = function()
        for _, r in ipairs(customRows) do r:Hide() end
        for i, entry in ipairs(ns.db.custom) do
            local r = customRows[i]
            if not r then
                r = CreateFrame("Frame", nil, child)
                r:SetSize(rowW, 28)
                r.bg = r:CreateTexture(nil, "BACKGROUND")
                r.bg:SetAllPoints()
                r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                r.text:SetPoint("LEFT", 8, 0)
                r.text:SetWidth(180)
                r.text:SetJustifyH("LEFT")
                r.text:SetWordWrap(false)
                r.cmd = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                r.cmd:SetPoint("LEFT", 196, 0)
                r.cmd:SetWidth(rowW - 330)
                r.cmd:SetJustifyH("LEFT")
                r.cmd:SetWordWrap(false)
                r.run = Button(r, L["Apply"], 80, 22)
                r.run:SetPoint("RIGHT", -34, 0)
                r.del = Button(r, "X", 26, 22)
                r.del:SetPoint("RIGHT", -4, 0)
                r:EnableMouse(true)
                r:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(self.entry.name)
                    GameTooltip:AddLine(self.entry.cmd, 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                r:SetScript("OnLeave", GameTooltip_Hide)
                customRows[i] = r
            end
            r.entry = entry
            r:SetPoint("TOPLEFT", 0, -(i - 1) * 28)
            r.bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.03 or 0)
            r.text:SetText(entry.name)
            r.cmd:SetText(entry.cmd)
            r.run:SetScript("OnClick", function() ns.Run(entry.cmd) end)
            r.del:SetScript("OnClick", function()
                table.remove(ns.db.custom, i)
                RefreshCustom()
            end)
            r:Show()
        end
        child:SetHeight(math.max(1, #ns.db.custom * 28))
        empty:SetShown(#ns.db.custom == 0)
    end
    p:SetScript("OnShow", RefreshCustom)
    RefreshCustom()
end

ns.RegisterPage({ key = "perso", label = "Custom", icon = "INV_Misc_Note_01", build = BuildCustomPage })
