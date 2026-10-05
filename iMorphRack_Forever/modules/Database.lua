-- iMorph Rack (Forever) : onglet Base de données
local _, ns = ...
local L, UI = ns.L, ns.UI
local Button, EditBox, Label, Heading, CommandRow = UI.Button, UI.EditBox, UI.Label, UI.Heading, UI.CommandRow
local W, COL2 = UI.WIDTH, UI.COL2

ns.pendingItems = {}

-- met l'ID dans le champ de l'emplacement (onglet Objets)
function ns.SetItemSlot(slot, id)
    ns.pendingItems[slot] = tostring(id)
    if ns.itemBoxes and ns.itemBoxes[slot] then ns.itemBoxes[slot]:SetText(tostring(id)) end
end

-- Aperçu : cabine d'essayage de Blizzard
function ns.Preview(itemID)
    local _, link = (C_Item and C_Item.GetItemInfo or GetItemInfo)(itemID)
    link = link or ("|cffffffff|Hitem:" .. itemID .. "::::::::::::|h[" .. itemID .. "]|h|r")
    if DressUpItemLink then DressUpItemLink(link)
    elseif DressUpLink then DressUpLink(link)
    else HandleModifiedItemClick(link) end
end

local DB_ROW_H, DB_ROWS = 22, 13
local NAME_EN, NAME_FR = 7, 8

local function SlotName(id)
    for _, s in ipairs(ns.SLOTS) do if s.id == id then return L[s.name] end end
    return "?"
end

local function CategoryName(cat)
    for _, c in ipairs(ns.CATEGORIES) do if c.id == cat then return L[c.name] end end
    return L["Other"]
end

local QUALITIES = { 0, 1, 2, 3, 4, 5, 6 }
local function QualityName(q)
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
    return (c and c.hex or "") .. (_G["ITEM_QUALITY" .. q .. "_DESC"] or q) .. "|r"
end

-- petit menu déroulant avec une liste { valeur, texte }
local function Dropdown(name, parent, width, getItems, onPick)
    local d = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(d, width)
    d.value = getItems()[1][1]
    UIDropDownMenu_Initialize(d, function()
        for _, o in ipairs(getItems()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = o[2], d.value == o[1]
            info.func = function()
                d.value = o[1]
                UIDropDownMenu_SetText(d, o[2])
                onPick()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(d, getItems()[1][2])
    return d
end

local function BuildDatabasePage(p)
    local results = {}
    local sortKey, sortDesc = "name", false
    local Filter, Update
    local ready = false

    -- ligne 1 : recherche + filtres
    local search = EditBox(p, 160)
    search:SetPoint("TOPLEFT", 6, -4)
    local hint = search:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hint:SetPoint("LEFT", 2, 0)
    hint:SetText(L["Search name or ID"])

    local slotDrop = Dropdown("iMorphRackSlotDropDown", p, 105, function()
        local t = { { 0, L["All slots"] } }
        for _, s in ipairs(ns.SLOTS) do t[#t + 1] = { s.id, L[s.name] } end
        return t
    end, function() Filter() end)
    slotDrop:SetPoint("LEFT", search, "RIGHT", -8, -2)

    local catDrop = Dropdown("iMorphRackCatDropDown", p, 115, function()
        local t = { { 0, L["All categories"] } }
        for _, c in ipairs(ns.CATEGORIES) do t[#t + 1] = { c.id, L[c.name] } end
        t[#t + 1] = { -1, L["Other"] }
        return t
    end, function() Filter() end)
    catDrop:SetPoint("LEFT", slotDrop, "RIGHT", -28, 0)

    local qualDrop = Dropdown("iMorphRackQualDropDown", p, 105, function()
        local t = { { -1, L["All qualities"] } }
        for _, q in ipairs(QUALITIES) do t[#t + 1] = { q, QualityName(q) } end
        return t
    end, function() Filter() end)
    qualDrop:SetPoint("LEFT", catDrop, "RIGHT", -28, 0)

    -- ligne 2 : niveau requis, nombre de résultats, ID copié
    Label(p, L["Required level"]):SetPoint("TOPLEFT", 0, -38)
    local minLvl = EditBox(p, 30)
    minLvl:SetNumeric(true)
    minLvl:SetMaxLetters(2)
    minLvl:SetPoint("TOPLEFT", 120, -34)
    Label(p, "-"):SetPoint("LEFT", minLvl, "RIGHT", 4, 0)
    local maxLvl = EditBox(p, 30)
    maxLvl:SetNumeric(true)
    maxLvl:SetMaxLetters(2)
    maxLvl:SetPoint("LEFT", minLvl, "RIGHT", 16, 0)
    for _, e in ipairs({ minLvl, maxLvl }) do
        e:SetScript("OnTextChanged", function() if ready then Filter() end end)
        e:SetScript("OnEnterPressed", e.ClearFocus)
    end

    local status = Label(p, "", "GameFontNormalSmall")
    status:SetPoint("LEFT", maxLvl, "RIGHT", 20, 0)

    Label(p, L["Copied ID:"]):SetPoint("TOPRIGHT", -106, -38)
    local copy = EditBox(p, 90)
    copy:SetPoint("TOPRIGHT", -8, -34)
    copy:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    -- liste
    local box = UI.ListBox(p)
    box:SetPoint("TOPLEFT", 0, -62)
    box:SetPoint("BOTTOMRIGHT", 0, 0)

    local rowW = W - 60 - 40
    -- colonnes : { clé de tri, libellé, x, largeur }
    local COLS = {
        { "name", L["Name"],     28,         rowW - 388 },
        { "cat",  L["Category"], rowW - 356, 110 },
        { "slot", L["Slot"],     rowW - 242, 90 },
        { "req",  L["Level"],    rowW - 148, 44 },
        { "ilvl", L["iLvl"],     rowW - 100, 44 },
        { "id",   "ID",          rowW - 52,  50 },
    }

    -- en-têtes cliquables pour trier
    local head = CreateFrame("Frame", nil, box)
    head:SetPoint("TOPLEFT", 6, -5)
    head:SetSize(rowW, 20)
    local hbg = head:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints()
    hbg:SetColorTexture(1, 0.82, 0, 0.12)
    local heads = {}
    for _, c in ipairs(COLS) do
        local h = CreateFrame("Button", nil, head)
        h:SetPoint("TOPLEFT", c[3], 0)
        h:SetSize(c[4], 20)
        h.text = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h.text:SetPoint("LEFT", 0, 0)
        h.text:SetText(c[2])
        h.arrow = h:CreateTexture(nil, "OVERLAY")
        h.arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
        h.arrow:SetSize(9, 8)
        h.arrow:SetPoint("LEFT", h.text, "RIGHT", 3, 0)
        local hl = h:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        h:SetScript("OnClick", function()
            if sortKey == c[1] then
                sortDesc = not sortDesc
            else
                -- nombres : du plus grand au plus petit par défaut
                sortKey, sortDesc = c[1], c[1] == "req" or c[1] == "ilvl"
            end
            Filter()
        end)
        h.key = c[1]
        heads[#heads + 1] = h
    end

    local scroll = CreateFrame("ScrollFrame", "iMorphRackDBScroll", box, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -26)
    scroll:SetPoint("BOTTOMRIGHT", -28, 6)

    local rows = {}

    local function OnRowClick(row, button)
        local it = row.item
        if not it then return end
        -- Ctrl+clic : aperçu dans la cabine d'essayage
        if IsModifiedClick("DRESSUP") or IsControlKeyDown() then
            ns.Preview(it[1])
            return
        end
        if IsModifiedClick("CHATLINK") then
            local _, link = (C_Item and C_Item.GetItemInfo or GetItemInfo)(it[1])
            if link then ChatEdit_InsertLink(link) end
            return
        end
        copy:SetText(tostring(it[1]))
        copy:SetFocus()
        copy:HighlightText()
        ns.SetItemSlot(it[2], it[1])
        if button == "RightButton" then ns.Run(".item " .. it[2] .. " " .. it[1]) end
    end

    local function Col(r, i, font)
        local fs = r:CreateFontString(nil, "OVERLAY", font)
        fs:SetPoint("LEFT", COLS[i][3], 0)
        fs:SetWidth(COLS[i][4] - 4)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)
        return fs
    end

    for i = 1, DB_ROWS do
        local r = CreateFrame("Button", nil, box)
        r:SetSize(rowW, DB_ROW_H)
        r:SetPoint("TOPLEFT", 6, -26 - (i - 1) * DB_ROW_H)
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18)
        r.icon:SetPoint("LEFT", 4, 0)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        r.name = Col(r, 1, "GameFontHighlight")
        r.cat = Col(r, 2, "GameFontHighlightSmall")
        r.slot = Col(r, 3, "GameFontDisableSmall")
        r.req = Col(r, 4, "GameFontHighlightSmall")
        r.ilvl = Col(r, 5, "GameFontDisableSmall")
        r.id = Col(r, 6, "GameFontNormalSmall")
        r:SetScript("OnClick", OnRowClick)
        r:SetScript("OnEnter", function(self)
            if not self.item then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.item[1])
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Click: copy the ID"], 0.4, 1, 0.4)
            GameTooltip:AddLine(L["Right-click: copy and apply"], 0.4, 1, 0.4)
            GameTooltip:AddLine(L["Ctrl+click: preview"], 0.4, 1, 0.4)
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", GameTooltip_Hide)
        rows[i] = r
    end

    Update = function()
        local offset = FauxScrollFrame_GetOffset(scroll)
        FauxScrollFrame_Update(scroll, #results, DB_ROWS, DB_ROW_H)
        local nameIdx = ns.IS_FRENCH and NAME_FR or NAME_EN
        for i, r in ipairs(rows) do
            local it = results[offset + i]
            r.item = it
            if it then
                local q = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[it[3]]
                r.name:SetText((q and q.hex or "|cffffffff") .. it[nameIdx] .. "|r")
                r.cat:SetText(CategoryName(it[6]))
                r.slot:SetText(SlotName(it[2]))
                r.req:SetText(it[5] > 0 and it[5] or "-")
                r.ilvl:SetText(it[4])
                r.id:SetText(it[1])
                r.icon:SetTexture(C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(it[1]) or (GetItemIcon and GetItemIcon(it[1])))
                r.bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.03 or 0)
                r:Show()
            else
                r:Hide()
            end
        end
        for _, h in ipairs(heads) do
            h.arrow:SetShown(h.key == sortKey)
            if sortDesc then h.arrow:SetTexCoord(0, 0.5625, 1, 0) else h.arrow:SetTexCoord(0, 0.5625, 0, 1) end
        end
    end
    scroll:SetScript("OnVerticalScroll", function(self, delta)
        FauxScrollFrame_OnVerticalScroll(self, delta, DB_ROW_H, Update)
    end)

    local nameIdx = ns.IS_FRENCH and NAME_FR or NAME_EN
    local function SortValue(it, key)
        if key == "name" then return it[nameIdx]
        elseif key == "cat" then return it[6]
        elseif key == "slot" then return it[2]
        elseif key == "req" then return it[5]
        elseif key == "ilvl" then return it[4]
        else return it[1] end
    end

    local known = {}
    for _, c in ipairs(ns.CATEGORIES) do known[c.id] = true end

    Filter = function()
        wipe(results)
        local text = strtrim(search:GetText()):lower()
        local num = tonumber(text)
        local lo, hi = tonumber(minLvl:GetText()) or 0, tonumber(maxLvl:GetText()) or 999
        local slot, cat, qual = slotDrop.value, catDrop.value, qualDrop.value
        for _, it in ipairs(ns.ITEMS) do
            if (slot == 0 or it[2] == slot)
                and (cat == 0 or it[6] == cat or (cat == -1 and not known[it[6]]))
                and (qual == -1 or it[3] == qual)
                and it[5] >= lo and it[5] <= hi
                and (text == "" or (num and tostring(it[1]):find(text, 1, true))
                    or it[NAME_EN]:lower():find(text, 1, true) or it[NAME_FR]:lower():find(text, 1, true)) then
                results[#results + 1] = it
            end
        end
        table.sort(results, function(a, b)
            local va, vb = SortValue(a, sortKey), SortValue(b, sortKey)
            if va == vb then return a[1] < b[1] end
            if sortDesc then return va > vb end
            return va < vb
        end)
        status:SetText(format(L["%d items"], #results))
        FauxScrollFrame_SetOffset(scroll, 0)
        scroll:SetVerticalScroll(0)
        Update()
    end

    search:SetScript("OnTextChanged", function(self)
        hint:SetShown(self:GetText() == "")
        if ready then Filter() end
    end)
    search:SetScript("OnEnterPressed", search.ClearFocus)

    ready = true
    Filter()
end

ns.RegisterPage({ key = "db", label = "Database", icon = "INV_Misc_Book_09", build = BuildDatabasePage })
