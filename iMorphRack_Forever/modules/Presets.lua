-- iMorph Rack (Forever) : onglet Presets (looks enregistrés, réapplication à la connexion)
local _, ns = ...
local L, UI, S = ns.L, ns.UI, ns.Skin
local C = S.C
local Button, EditBox, Label, Heading = UI.Button, UI.EditBox, UI.Label, UI.Heading

local ROW_H = 32

local function Notify(msg) print("|cff4fd2ffiMorph Rack|r : " .. msg) end

local function BuildPresetsPage(p)
    local Refresh

    -- Look actuel ------------------------------------------------------------------
    local cur = Heading(p, L["Current look"], 0, 0)

    local well = CreateFrame("Frame", nil, p)
    well:SetPoint("TOPLEFT", 0, -30)
    well:SetSize(UI.PAGE_W, 50)
    S.Rounded(well, 6, C.well, { 0.02, 0.035, 0.06, 1 }, C.trim)
    local cmds = S.Text(well, 11, "muted")
    cmds:SetPoint("TOPLEFT", 10, -8)
    cmds:SetPoint("BOTTOMRIGHT", -10, 8)
    cmds:SetJustifyV("TOP")
    cmds:SetMaxLines(3)
    UI.Tooltip(well, L["Current look"], function() return ns.LookCommands(ns.CharDB().look) end)

    local name = EditBox(p, 230, L["Preset name"])
    name:SetPoint("TOPLEFT", 0, -92)
    local function saveCurrent()
        local n = strtrim(name:GetText())
        local text, count = ns.LookCommands(ns.CharDB().look)
        if count == 0 then Notify(L["Nothing to save: change your look first."]) return end
        if n == "" then name:SetFocus() return end
        local function doSave()
            ns.SavePreset(n, text)
            name:SetText("")
            name:ClearFocus()
            Notify(format(L["Preset \"%s\" saved."], n))
            Refresh()
        end
        if ns.FindPreset(n) then
            UI.Confirm(format(L["Replace the preset \"%s\"?"], n), doSave)
        else
            doSave()
        end
    end
    name:SetScript("OnEnterPressed", saveCurrent)
    local saveBtn = Button(p, L["Save as preset"], 150, 24, saveCurrent, true)
    saveBtn:SetPoint("LEFT", name, "RIGHT", 10, 0)
    local reapply = Button(p, L["Reapply"], 120, 24, function()
        local text, count = ns.LookCommands(ns.CharDB().look)
        if count > 0 then ns.Run(text) end
    end)
    reapply:SetPoint("LEFT", saveBtn, "RIGHT", 8, 0)
    UI.Tooltip(reapply, L["Reapply"], L["Sends the current look again (e.g. after a loading screen)."])
    local reset = Button(p, L["Reset (.reset)"], 140, 24, function() ns.Run(".reset") end)
    reset:SetPoint("TOPRIGHT", 0, -92)

    -- À la connexion ---------------------------------------------------------------
    Heading(p, L["At login"], 0, -134)
    Label(p, L["Reapply automatically on this character:"], 12, "text"):SetPoint("TOPLEFT", 0, -172)
    local auto = S.Dropdown(p, 220, 240, function()
        local t = { { "off", L["Off"] }, { "last", L["Last look"] } }
        for _, pr in ipairs(ns.db.presets) do
            t[#t + 1] = { pr.name, "|cffffc23c" .. L["Preset:"] .. "|r " .. pr.name }
        end
        return t
    end, function() return ns.CharDB().auto or "off" end, function(v)
        ns.CharDB().auto = v
    end, { maxRows = 12 })
    auto:SetPoint("TOPLEFT", 300, -166)
    Label(p, L["Waits for iMorph to be injected, then applies the look."], 11, "muted")
        :SetPoint("TOPLEFT", 0, -194)

    -- Mes presets ------------------------------------------------------------------
    local list = Heading(p, L["My presets"], 0, -222)
    local import = Button(p, L["Import"], 90, 20, function()
        UI.Prompt(L["Paste the commands of the preset:"], "", function(text)
            text = strtrim(text or "")
            if text == "" then return end
            local ok, word = ns.IsAllowed(text)
            if not ok then
                Notify(L["Command not allowed"] .. " (" .. word .. ").")
                return
            end
            -- les commandes peuvent être précédées du nom : "Nom = .race 4; ..."
            local n, c = text:match("^(.-)%s*=%s*(%..+)$")
            local function finish(pname)
                pname = strtrim(pname or "")
                if pname == "" then return end
                ns.SavePreset(pname, c or text)
                Notify(format(L["Preset \"%s\" saved."], pname))
                Refresh()
            end
            if n and n ~= "" then finish(n)
            else UI.Prompt(L["Name of the preset:"], "", finish) end
        end)
    end)
    import:SetPoint("RIGHT", list, "RIGHT", 0, 3)
    list.right:ClearAllPoints()
    list.right:SetPoint("RIGHT", import, "LEFT", -10, 0)

    local box = UI.ListBox(p)
    box:SetPoint("TOPLEFT", 0, -250)
    box:SetPoint("BOTTOMRIGHT", 0, 0)
    local scroll, child = S.Scroll(box)
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -16, 6)
    local rowW = UI.PAGE_W - 22
    child:SetWidth(rowW)

    local empty = S.Text(box, 13, "muted")
    empty:SetPoint("CENTER")
    empty:SetWidth(UI.PAGE_W - 80)
    empty:SetJustifyH("CENTER")
    empty:SetText(L["No preset yet. Change your look, give it a name above and click \"Save as preset\"."])

    local rows = {}
    Refresh = function()
        local text, count = ns.LookCommands(ns.CharDB().look)
        cmds:SetText(count > 0 and text or L["No change tracked yet: the commands you send are recorded here."])
        cur.right:SetText(format(L["%d commands"], count))
        list.right:SetText(format(L["%d presets"], #ns.db.presets))
        auto.Refresh()

        for _, r in ipairs(rows) do r:Hide() end
        for i, pr in ipairs(ns.db.presets) do
            local r = rows[i]
            if not r then
                r = CreateFrame("Frame", nil, child)
                r:SetSize(rowW, ROW_H)
                r:EnableMouse(true)
                r:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(self.preset.name)
                    GameTooltip:AddLine(self.preset.cmd:gsub(";%s*", "\n"), 1, 1, 1)
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("/imr " .. self.preset.name, 0.4, 1, 0.4)
                    GameTooltip:Show()
                end)
                r:SetScript("OnLeave", GameTooltip_Hide)
                S.RowHighlight(r)
                r.bg = r:CreateTexture(nil, "BACKGROUND")
                r.bg:SetAllPoints()
                r.icon = S.Icon(r, 22)
                r.icon:SetPoint("LEFT", 6, 0)
                r.icon.tex:SetTexture("Interface\\Icons\\INV_Chest_Cloth_17")
                r.text = S.Text(r, 13, "gold")
                r.text:SetPoint("LEFT", r.icon, "RIGHT", 10, 0)
                r.text:SetWidth(200)
                r.text:SetWordWrap(false)
                r.count = S.Text(r, 11, "muted")
                r.count:SetPoint("LEFT", 246, 0)
                r.run = Button(r, L["Apply"], 84, 22, nil, true)
                r.run:SetPoint("RIGHT", -270, 0)
                r.update = Button(r, L["Update"], 90, 22)
                r.update:SetPoint("RIGHT", -174, 0)
                r.export = Button(r, L["Export"], 70, 22)
                r.export:SetPoint("RIGHT", -100, 0)
                r.rename = Button(r, L["Rename"], 64, 22)
                r.rename:SetPoint("RIGHT", -32, 0)
                r.del = Button(r, "x", 26, 22)
                r.del:SetPoint("RIGHT", -2, 0)
                rows[i] = r
            end
            r.preset = pr
            r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
            r.bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.025 or 0)
            r.text:SetText(pr.name)
            r.count:SetText(format(L["%d commands"], ns.CountCommands(pr.cmd)))
            r.run:SetScript("OnClick", function() ns.ApplyPreset(pr) end)
            r.update:SetScript("OnClick", function()
                local t, n = ns.LookCommands(ns.CharDB().look)
                if n == 0 then Notify(L["Nothing to save: change your look first."]) return end
                UI.Confirm(format(L["Replace the preset \"%s\"?"], pr.name), function()
                    pr.cmd = t
                    Refresh()
                end)
            end)
            r.export:SetScript("OnClick", function()
                UI.Dialog(L["Copy this text (Ctrl+C) to share the preset:"], nil,
                    { input = true, text = pr.name .. " = " .. pr.cmd, noCancel = true })
            end)
            r.rename:SetScript("OnClick", function()
                UI.Prompt(L["New name:"], pr.name, function(v)
                    v = strtrim(v or "")
                    if v == "" or v == pr.name then return end
                    local other = ns.FindPreset(v)
                    if other and other ~= pr then Notify(format(L["A preset named \"%s\" already exists."], v)) return end
                    local c = ns.CharDB()
                    if c.auto == pr.name then c.auto = v end
                    pr.name = v
                    Refresh()
                end)
            end)
            r.del:SetScript("OnClick", function()
                UI.Confirm(format(L["Delete \"%s\"?"], pr.name), function()
                    for k, e in ipairs(ns.db.presets) do
                        if e == pr then table.remove(ns.db.presets, k) break end
                    end
                    local c = ns.CharDB()
                    if c.auto == pr.name then c.auto = "off" end
                    Refresh()
                end)
            end)
            r:Show()
        end
        child:SetHeight(math.max(1, #ns.db.presets * ROW_H))
        empty:SetShown(#ns.db.presets == 0)
    end

    ns.OnLookChanged = function() if p:IsVisible() then Refresh() end end
    p:SetScript("OnShow", Refresh)
    Refresh()
end

ns.RegisterPage({ key = "presets", label = "Presets", icon = "INV_Chest_Cloth_17", build = BuildPresetsPage })
