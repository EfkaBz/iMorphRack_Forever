-- iMorph Rack (Forever) : fenêtre principale (onglets animés, langue, état d'iMorph, avertissement)
local ADDON, ns = ...
local L, UI, S = ns.L, ns.UI, ns.Skin
local C = S.C
local main

-- onglets, remplis par les modules de page dans l'ordre du .toc
ns.PAGES = {}
function ns.RegisterPage(page) ns.PAGES[#ns.PAGES + 1] = page end

local TAB_Y, TAB_H, TAB_GAP = -48, 28, 6

local function SelectTab(key, instant)
    ns.db.tab = key
    for _, tab in ipairs(main.tabs) do
        local active = tab.info.key == key
        tab.text:SetTextColor(S.Color(active and C.gold or C.text))
        S.TintBorder(tab, active and C.gold or C.trim, instant and 0.01 or 0.2)
        tab.borderBase = active and C.gold or C.trim
        if active then
            -- le soulignement glisse sous l'onglet actif
            local to = tab.x
            if instant or not main.indX then
                main.indX = to
                main.indicator:SetPoint("TOPLEFT", to, TAB_Y - TAB_H - 3)
            else
                S.Tween(main.indicator, { dur = 0.3, from = main.indX, to = to, ease = "outCubic", set = function(v)
                    main.indX = v
                    main.indicator:SetPoint("TOPLEFT", v, TAB_Y - TAB_H - 3)
                end })
            end
            if not tab.page then
                tab.page = CreateFrame("Frame", nil, main.pageArea)
                tab.page:SetSize(UI.PAGE_W, UI.PAGE_H)
                tab.page:SetPoint("TOPLEFT")
                tab.info.build(tab.page)
            end
            if not tab.page:IsShown() or instant then
                tab.page:Show()
                if not instant then
                    -- fondu + léger glissement de la nouvelle page
                    tab.page:SetAlpha(0)
                    S.Tween(tab.page, { dur = 0.25, from = 0, to = 1, ease = "outCubic", set = function(v)
                        tab.page:SetAlpha(v)
                        tab.page:SetPoint("TOPLEFT", 12 * (1 - v), 0)
                    end })
                end
            end
        elseif tab.page then
            S.StopTween(tab.page)
            tab.page:Hide()
        end
    end
end

local function BuildTabs(f)
    local n = #ns.PAGES
    local tabW = math.floor((UI.WIDTH - 32 - TAB_GAP * (n - 1)) / n)

    -- soulignement doré + halo cyan sous l'onglet actif
    local ind = CreateFrame("Frame", nil, f)
    ind:SetSize(tabW, 2)
    f.indicator = ind
    local line = ind:CreateTexture(nil, "OVERLAY")
    line:SetPoint("LEFT", 10, 0); line:SetPoint("RIGHT", -10, 0); line:SetHeight(2)
    S.Gradient(line, { C.gold[1], C.gold[2], C.gold[3], 0.2 }, { C.gold[1], C.gold[2], C.gold[3], 1 }, true)
    local line2 = ind:CreateTexture(nil, "OVERLAY")
    line2:SetPoint("LEFT", ind, "CENTER"); line2:SetPoint("RIGHT", -10, 0); line2:SetHeight(2)
    S.Gradient(line2, { C.gold[1], C.gold[2], C.gold[3], 1 }, { C.gold[1], C.gold[2], C.gold[3], 0.2 }, true)
    line:SetPoint("RIGHT", ind, "CENTER")
    local halo = ind:CreateTexture(nil, "ARTWORK")
    halo:SetTexture(S.MEDIA .. "Glow")
    halo:SetBlendMode("ADD")
    halo:SetPoint("CENTER")
    halo:SetSize(tabW * 0.9, 18)
    halo:SetVertexColor(0.3, 0.8, 1, 0.45)

    f.tabs = {}
    for i, info in ipairs(ns.PAGES) do
        local tab = CreateFrame("Button", nil, f)
        tab.info = info
        tab.x = 16 + (i - 1) * (tabW + TAB_GAP)
        tab:SetSize(tabW, TAB_H)
        tab:SetPoint("TOPLEFT", tab.x, TAB_Y)
        tab:SetScript("OnClick", function() SelectTab(info.key) end)
        S.Rounded(tab, 6, C.btn1, C.btn2, C.trim)
        local glow = tab:CreateTexture(nil, "ARTWORK", nil, 2)
        glow:SetPoint("TOPLEFT", 2, -2); glow:SetPoint("BOTTOMRIGHT", -2, 2)
        S.Gradient(glow, { 0.3, 0.8, 1, 0 }, { 0.3, 0.8, 1, 0.22 })
        glow:SetBlendMode("ADD")
        S.HoverFade(tab, glow)
        tab:HookScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
        tab:HookScript("OnLeave", function(self)
            self.text:SetTextColor(S.Color(ns.db.tab == info.key and C.gold or C.text))
        end)

        local icon = S.Icon(tab, 18)
        icon:SetPoint("LEFT", 6, 0)
        icon.tex:SetTexture("Interface\\Icons\\" .. info.icon)
        tab.text = S.Text(tab, 12, "text")
        tab.text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        tab.text:SetText(L[info.label])
        S.FitText(tab.text, tabW - 36, 12)
        f.tabs[i] = tab
    end
end

-- avertissement si iMorph.exe n'est pas injecté
local function BuildWarning(f)
    local warn = CreateFrame("Frame", nil, f)
    warn:SetPoint("TOPLEFT", 1, -40)
    warn:SetPoint("BOTTOMRIGHT", -1, 1)
    warn:SetFrameLevel(f:GetFrameLevel() + 50)
    warn:EnableMouse(true) -- bloque les clics sur la fenêtre derrière
    S.Rounded(warn, 12, { 0.03, 0.05, 0.09, 0.97 }, { 0.01, 0.02, 0.04, 0.98 }, { 0, 0, 0, 0 })

    local pulse = warn:CreateTexture(nil, "ARTWORK")
    pulse:SetTexture(S.MEDIA .. "Glow")
    pulse:SetBlendMode("ADD")
    pulse:SetSize(150, 150)
    pulse:SetPoint("CENTER", 0, 90)
    pulse:SetVertexColor(1, 0.55, 0.15, 0.7)
    local mark = S.Text(warn, 64, "gold")
    mark:SetPoint("CENTER", pulse, "CENTER", 0, 0)
    mark:SetJustifyH("CENTER")
    mark:SetText("!")
    local clock = 0
    warn:SetScript("OnUpdate", function(_, e)
        clock = clock + e
        pulse:SetAlpha(0.55 + 0.35 * math.sin(clock * 2.4))
    end)

    local title = S.Text(warn, 20, "gold")
    title:SetPoint("TOP", pulse, "BOTTOM", 0, -2)
    title:SetJustifyH("CENTER")
    title:SetText(L["iMorph is not running"])
    local msg = S.Text(warn, 13, "text")
    msg:SetPoint("TOP", title, "BOTTOM", 0, -14)
    msg:SetWidth(UI.WIDTH - 180)
    msg:SetJustifyH("CENTER")
    msg:SetText(L["Launch iMorph and inject it into the game, then the commands will work. This window will disappear on its own."])
    local ignore = UI.Button(warn, L["Continue anyway"], 200, 26, function()
        warn.ignored = true
        S.FadeTo(warn, 0, 0.25, function() warn:Hide(); warn:SetAlpha(1) end)
    end)
    ignore:SetPoint("TOP", msg, "BOTTOM", 0, -26)

    local function Check()
        local show = not ns.IsInjected() and not warn.ignored
        if show and not warn:IsShown() then
            warn:SetAlpha(0); warn:Show(); S.FadeTo(warn, 1, 0.25)
        elseif not show and warn:IsShown() and not S.IsTweening(warn) then
            S.FadeTo(warn, 0, 0.3, function() warn:Hide(); warn:SetAlpha(1) end)
        end
        f.status:Update()
    end
    local t = 0
    f:HookScript("OnUpdate", function(_, e)
        t = t + e
        if t > 1 then t = 0; Check() end
    end)
    f:HookScript("OnShow", Check)
    warn:SetShown(not ns.IsInjected())
end

-- pied de page : état d'iMorph (point qui pulse) + langue
local function BuildFooter(f)
    local status = CreateFrame("Frame", nil, f)
    status:SetSize(220, 20)
    status:SetPoint("BOTTOMLEFT", 18, 14)
    local dot = status:CreateTexture(nil, "OVERLAY")
    dot:SetTexture(S.MEDIA .. "Dot")
    dot:SetSize(8, 8)
    dot:SetPoint("LEFT")
    local glow = status:CreateTexture(nil, "ARTWORK")
    glow:SetTexture(S.MEDIA .. "Glow")
    glow:SetBlendMode("ADD")
    glow:SetSize(26, 26)
    glow:SetPoint("CENTER", dot)
    local text = S.Text(status, 12, "muted")
    text:SetPoint("LEFT", dot, "RIGHT", 8, 0)
    local clock = 0
    status:SetScript("OnUpdate", function(_, e)
        clock = clock + e
        glow:SetAlpha(0.45 + 0.35 * math.sin(clock * 2))
    end)
    function status:Update()
        local on = ns.IsInjected()
        local c = on and C.good or C.bad
        dot:SetVertexColor(S.Color(c))
        glow:SetVertexColor(c[1], c[2], c[3], 0.6)
        text:SetText(on and L["iMorph detected"] or L["iMorph not detected"])
    end
    status:Update()
    f.status = status
end

local function Build()
    local getMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local f = S.Window("iMorphRackFrame", UIParent, UI.WIDTH, UI.HEIGHT, "iMorph Rack")
    main = f
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    local pos = ns.db.pos
    if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else f:SetPoint("CENTER") end
    S.Draggable(f, f.titleBar, function(self)
        local p, _, rp, x, y = self:GetPoint(1)
        ns.db.pos = { p, rp, x, y }
    end)
    tinsert(UISpecialFrames, f:GetName())

    local icon = S.Icon(f.titleBar, 24)
    icon:SetPoint("LEFT", 12, 0)
    icon.tex:SetTexture(ns.ICON)
    icon.tex:SetTexCoord(0, 1, 0, 1)
    f.title:ClearAllPoints()
    f.title:SetPoint("LEFT", icon, "RIGHT", 10, 0)

    -- titre, "Forever", version, puis bouton Bug et langue à droite (comme les autres addons)
    local forever = S.Text(f.titleBar, 15, "accent")
    forever:SetPoint("LEFT", f.title, "RIGHT", 5, 0)
    forever:SetText("Forever")
    local version = S.Text(f.titleBar, 11, "muted")
    version:SetPoint("BOTTOMLEFT", forever, "BOTTOMRIGHT", 6, 1)
    version:SetText("v" .. (getMeta(ADDON, "Version") or "?"))

    f.lang = UI.LanguageSelector(f.titleBar)
    f.lang:SetPoint("RIGHT", f.close, "LEFT", -8, 0)
    f.lang:SetFrameLevel(f.titleBar:GetFrameLevel() + 5)
    local bug = UI.BugButton(f.titleBar)
    bug:SetPoint("RIGHT", f.lang, "LEFT", -6, 0)
    bug:SetFrameLevel(f.titleBar:GetFrameLevel() + 5)

    f.pageArea = CreateFrame("Frame", nil, f)
    f.pageArea:SetPoint("TOPLEFT", 20, -92)
    f.pageArea:SetPoint("BOTTOMRIGHT", -20, 46)

    local rule = S.Rule(f, C.trim, 0.6)
    rule:SetPoint("BOTTOMLEFT", 20, 40)
    rule:SetPoint("BOTTOMRIGHT", -20, 40)

    BuildTabs(f)
    BuildFooter(f)

    local valid = false
    for _, t in ipairs(ns.PAGES) do if t.key == ns.db.tab then valid = true end end
    SelectTab(valid and ns.db.tab or ns.PAGES[1].key, true)

    BuildWarning(f)
end

function ns.Toggle()
    if not main then Build() main:Show() return end
    if main:IsShown() then S.AnimateClose(main) else main:Show() end
end

-- ouvre la fenêtre sur un onglet donné
function ns.ShowTab(key)
    if not main then Build() end
    if not main:IsShown() then main:Show() end
    SelectTab(key)
end
