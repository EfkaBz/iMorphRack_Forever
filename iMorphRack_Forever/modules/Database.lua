-- iMorph Rack (Forever) : onglet Base de données
local _, ns = ...
local L, UI, S = ns.L, ns.UI, ns.Skin
local C = S.C
local EditBox, Label = UI.EditBox, UI.Label

ns.pendingItems = {}

-- met l'ID dans le champ de l'emplacement (onglet Objets)
function ns.SetItemSlot(slot, id)
    ns.pendingItems[slot] = tostring(id)
    if ns.itemBoxes and ns.itemBoxes[slot] then ns.itemBoxes[slot]:SetText(tostring(id)) end
end

-- Aperçu : cabine d'essayage du jeu
function ns.Preview(itemID)
    local _, link = (C_Item and C_Item.GetItemInfo or GetItemInfo)(itemID)
    link = link or ("|cffffffff|Hitem:" .. itemID .. "::::::::::::|h[" .. itemID .. "]|h|r")
    if DressUpItemLink then DressUpItemLink(link)
    elseif DressUpLink then DressUpLink(link)
    else HandleModifiedItemClick(link) end
end

local DB_ROW_H = 22
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

local function BuildDatabasePage(p)
    local results = {}
    local sortKey, sortDesc = "name", false
    local slotV, catV, qualV = 0, 0, -1
    local offset = 0
    local Filter, Update
    local ready = false

    -- ligne 1 : recherche + filtres
    local search = EditBox(p, 180, L["Search name or ID"])
    search:SetPoint("TOPLEFT", 0, 0)

    local slotDrop = S.Dropdown(p, 140, 170, function()
        local t = { { 0, L["All slots"] } }
        for _, s in ipairs(ns.SLOTS) do t[#t + 1] = { s.id, L[s.name] } end
        return t
    end, function() return slotV end, function(v) slotV = v; Filter() end, { maxRows = 16 })
    slotDrop:SetPoint("LEFT", search, "RIGHT", 10, 0)

    local catDrop = S.Dropdown(p, 160, 190, function()
        local t = { { 0, L["All categories"] } }
        for _, c in ipairs(ns.CATEGORIES) do t[#t + 1] = { c.id, L[c.name] } end
        t[#t + 1] = { -1, L["Other"] }
        return t
    end, function() return catV end, function(v) catV = v; Filter() end, { maxRows = 16 })
    catDrop:SetPoint("LEFT", slotDrop, "RIGHT", 8, 0)

    local qualDrop = S.Dropdown(p, 140, 160, function()
        local t = { { -1, L["All qualities"] } }
        for _, q in ipairs(QUALITIES) do t[#t + 1] = { q, QualityName(q) } end
        return t
    end, function() return qualV end, function(v) qualV = v; Filter() end)
    qualDrop:SetPoint("LEFT", catDrop, "RIGHT", 8, 0)

    -- ligne 2 : niveau requis, nombre de résultats, ID copié
    Label(p, L["Required level"], 12, "muted"):SetPoint("TOPLEFT", 0, -40)
    local minLvl = EditBox(p, 36)
    minLvl:SetNumeric(true)
    minLvl:SetMaxLetters(2)
    minLvl:SetPoint("TOPLEFT", 112, -35)
    Label(p, "-", 12, "muted"):SetPoint("LEFT", minLvl, "RIGHT", 6, 0)
    local maxLvl = EditBox(p, 36)
    maxLvl:SetNumeric(true)
    maxLvl:SetMaxLetters(2)
    maxLvl:SetPoint("LEFT", minLvl, "RIGHT", 18, 0)
    for _, e in ipairs({ minLvl, maxLvl }) do
        e:HookScript("OnTextChanged", function() if ready then Filter() end end)
        e:SetScript("OnEnterPressed", e.ClearFocus)
    end

    local status = Label(p, "", 12, "accent")
    status:SetPoint("LEFT", maxLvl, "RIGHT", 20, 0)

    local copy = EditBox(p, 90)
    copy:SetPoint("TOPRIGHT", 0, -35)
    copy:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
    Label(p, L["Copied ID:"], 12, "muted"):SetPoint("RIGHT", copy, "LEFT", -8, 0)

    -- liste
    local box = UI.ListBox(p)
    box:SetPoint("TOPLEFT", 0, -66)
    box:SetPoint("BOTTOMRIGHT", 0, 0)
    local boxH = UI.PAGE_H - 66
    local DB_ROWS = math.floor((boxH - 34) / DB_ROW_H)

    local rowW = UI.PAGE_W - 24
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
    head:SetPoint("TOPLEFT", 8, -6)
    head:SetSize(rowW, 22)
    local hbg = head:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints()
    S.Gradient(hbg, { C.ring[1], C.ring[2], C.ring[3], 0.16 }, { C.ring[1], C.ring[2], C.ring[3], 0.02 })
    local hline = head:CreateTexture(nil, "BORDER")
    hline:SetPoint("BOTTOMLEFT"); hline:SetPoint("BOTTOMRIGHT"); hline:SetHeight(1)
    S.Gradient(hline, { C.ring[1], C.ring[2], C.ring[3], 0.7 }, { C.ring[1], C.ring[2], C.ring[3], 0.05 }, true)
    local heads = {}
    for _, c in ipairs(COLS) do
        local h = CreateFrame("Button", nil, head)
        h:SetPoint("TOPLEFT", c[3], 0)
        h:SetSize(c[4], 22)
        h.text = S.Text(h, 11, "gold")
        h.text:SetPoint("LEFT", 0, 0)
        h.text:SetText(c[2])
        h.arrow = S.Chevron(h, C.accent)
        h.arrow:SetPoint("LEFT", h.text, "RIGHT", 4, 0)
        h:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
        h:SetScript("OnLeave", function(self) self.text:SetTextColor(S.Color(C.gold)) end)
        h:SetScript("OnClick", function()
            if sortKey == c[1] then
                sortDesc = not sortDesc
            else
                -- nombres : du plus grand au plus petit par défaut
                sortKey, sortDesc = c[1], c[1] == "req" or c[1] == "ilvl"
            end
            Filter(true)
        end)
        h.key = c[1]
        heads[#heads + 1] = h
    end

    local bar = S.ScrollBar(box, function(v)
        offset = v
        Update()
    end)
    bar:SetPoint("TOPRIGHT", -6, -32)
    bar:SetPoint("BOTTOMRIGHT", -6, 8)
    box:EnableMouseWheel(true)
    box:SetScript("OnMouseWheel", function(_, d)
        local _, hi = bar:GetMinMaxValues()
        bar:SetValue(math.max(0, math.min(hi, offset - d * 3)))
    end)

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
        -- petit éclair sur la ligne
        row.flash:SetAlpha(1)
        S.FadeTo(row.flash, 0, 0.5)
        if button == "RightButton" then ns.Run(".item " .. it[2] .. " " .. it[1]) end
    end

    local function Col(r, i, size, col)
        local fs = S.Text(r, size, col)
        fs:SetPoint("LEFT", COLS[i][3], 0)
        fs:SetWidth(COLS[i][4] - 4)
        fs:SetWordWrap(false)
        return fs
    end

    for i = 1, DB_ROWS do
        local r = CreateFrame("Button", nil, box)
        r:SetSize(rowW, DB_ROW_H)
        r:SetPoint("TOPLEFT", 8, -30 - (i - 1) * DB_ROW_H)
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
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
        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        S.RowHighlight(r)
        -- éclair au clic : un cadre à part (l'alpha d'une texture en dégradé n'est pas fiable)
        r.flash = CreateFrame("Frame", nil, r)
        r.flash:SetAllPoints()
        local flashTex = r.flash:CreateTexture(nil, "ARTWORK")
        flashTex:SetAllPoints()
        S.Gradient(flashTex, { 1, 0.76, 0.24, 0.35 }, { 1, 0.76, 0.24, 0 }, true)
        flashTex:SetBlendMode("ADD")
        r.flash:SetAlpha(0)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18)
        r.icon:SetPoint("LEFT", 5, 0)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        r.name = Col(r, 1, 12, "text")
        r.cat = Col(r, 2, 11, "text")
        r.slot = Col(r, 3, 11, "muted")
        r.req = Col(r, 4, 11, "text")
        r.ilvl = Col(r, 5, 11, "muted")
        r.id = Col(r, 6, 11, "accent")
        rows[i] = r
    end

    local empty = S.Text(box, 13, "muted")
    empty:SetPoint("CENTER", 0, -10)
    empty:SetText(L["No item matches these filters."])

    local getIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    Update = function()
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
                r.icon:SetTexture(getIcon and getIcon(it[1]))
                r.bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.025 or 0)
                r:Show()
            else
                r:Hide()
            end
        end
        empty:SetShown(#results == 0)
        for _, h in ipairs(heads) do
            h.arrow:SetShown(h.key == sortKey)
            if h.key == sortKey then h.arrow:Flip(not sortDesc) end
        end
    end

    local function SortValue(it, key)
        if key == "name" then return it[ns.IS_FRENCH and NAME_FR or NAME_EN]
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
        for _, it in ipairs(ns.ITEMS) do
            if (slotV == 0 or it[2] == slotV)
                and (catV == 0 or it[6] == catV or (catV == -1 and not known[it[6]]))
                and (qualV == -1 or it[3] == qualV)
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
        offset = 0
        bar:SetRange(#results - DB_ROWS, DB_ROWS, #results)
        bar:SetValue(0)
        Update()
    end

    search:HookScript("OnTextChanged", function() if ready then Filter() end end)
    search:SetScript("OnEnterPressed", search.ClearFocus)

    ready = true
    Filter()
end

ns.RegisterPage({ key = "db", label = "Database", icon = "INV_Misc_Book_09", build = BuildDatabasePage })
