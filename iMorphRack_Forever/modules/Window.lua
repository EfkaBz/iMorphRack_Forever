-- iMorph Rack (Forever) : fenêtre principale (onglets, langue, avertissement iMorph)
local ADDON, ns = ...
local L, UI = ns.L, ns.UI
local main

-- onglets, remplis par les modules de page dans l'ordre du .toc
ns.PAGES = {}
function ns.RegisterPage(page) ns.PAGES[#ns.PAGES + 1] = page end

local LANGUAGES = {
    { value = "auto", text = "Automatic (game language)" },
    { value = "enUS", text = "English" },
    { value = "frFR", text = "Français" },
}

StaticPopupDialogs.IMORPHRACK_RELOAD = {
    text = L["The interface will be reloaded to apply the language."],
    button1 = OKAY, button2 = CANCEL,
    OnAccept = function(_, lang) ns.db.lang = lang; ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

local function atlasExists(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

local function Parchment(f)
    local left = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    local right = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    left:SetPoint("TOPLEFT", 6, -62)
    left:SetPoint("BOTTOMRIGHT", f, "BOTTOM", 0, 6)
    right:SetPoint("TOPLEFT", f, "TOP", 0, -62)
    right:SetPoint("BOTTOMRIGHT", -6, 6)
    if atlasExists("spellbook-background-evergreen-left") then
        left:SetAtlas("spellbook-background-evergreen-left")
        right:SetAtlas("spellbook-background-evergreen-right")
    else
        left:SetTexture("Interface\\Spellbook\\Spellbook-Page-1")
        left:SetTexCoord(0, 0.86, 0, 0.9)
        right:SetTexture("Interface\\Spellbook\\Spellbook-Page-2")
        right:SetTexCoord(0, 0.86, 0, 0.9)
    end
end

local function SetPortrait(f)
    local tex = (f.PortraitContainer and f.PortraitContainer.portrait) or f.portrait
    if not tex then
        tex = f:CreateTexture(nil, "OVERLAY")
        tex:SetSize(58, 58)
        tex:SetPoint("TOPLEFT", -5, 7)
    end
    tex:SetTexture(ns.ICON)
    if tex.SetMask then tex:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask") end
end

local function SetTitle(f, text)
    if f.SetTitle then f:SetTitle(text) return end
    local t = f.TitleText or (f.TitleContainer and f.TitleContainer.TitleText)
    if not t then
        t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOP", 0, -5)
    end
    t:SetText(text)
end

local function SelectTab(key)
    ns.db.tab = key
    for _, tab in ipairs(main.tabs) do
        local active = tab.info.key == key
        tab:SetChecked(active)
        if active then
            main.pageTitle:SetText(L[tab.info.label])
            if not tab.page then
                tab.page = CreateFrame("Frame", nil, main.pageArea)
                tab.page:SetAllPoints()
                tab.info.build(tab.page)
            end
        end
        if tab.page then tab.page:SetShown(active) end
    end
end

local function Build()
    local ok, f = pcall(CreateFrame, "Frame", "iMorphRackFrame", UIParent, "PortraitFrameTemplate")
    if not ok then
        f = CreateFrame("Frame", "iMorphRackFrame", UIParent, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true, tileSize = 32, edgeSize = 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 },
        })
        f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        local close = f.CloseButton
        close:SetPoint("TOPRIGHT", -4, -4)
    end
    main = f
    -- la croix du modèle passe par HideUIPanel, bloqué en combat : on cache directement
    if f.CloseButton then f.CloseButton:SetScript("OnClick", function() f:Hide() end) end
    f:SetSize(UI.WIDTH, UI.HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    tinsert(UISpecialFrames, f:GetName())

    local getMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    SetTitle(f, "iMorph Rack (Forever)  |cff9d9d9dv" .. (getMeta(ADDON, "Version") or "?") .. "|r")
    SetPortrait(f)
    Parchment(f)

    -- onglets icônes sous le titre, comme le grimoire
    f.tabs = {}
    for i, info in ipairs(ns.PAGES) do
        local tab = CreateFrame("CheckButton", nil, f)
        tab.info = info
        tab:SetSize(34, 34)
        tab:SetPoint("TOPLEFT", 70 + (i - 1) * 42, -26)
        local icon = tab:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture("Interface\\Icons\\" .. info.icon)
        local border = tab:CreateTexture(nil, "OVERLAY")
        border:SetPoint("TOPLEFT", -3, 3)
        border:SetPoint("BOTTOMRIGHT", 3, -3)
        border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        border:SetTexCoord(0.2, 0.8, 0.2, 0.8)
        tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        tab:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
        tab:GetCheckedTexture():SetBlendMode("ADD")
        tab:SetScript("OnClick", function() SelectTab(info.key) end)
        tab:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(L[info.label])
            GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", GameTooltip_Hide)
        f.tabs[i] = tab
    end

    -- titre de page, comme l'en-tête "Général" du grimoire
    f.pageTitle = f:CreateFontString(nil, "OVERLAY", "QuestFont_Huge")
    f.pageTitle:SetPoint("TOPLEFT", 36, -76)
    UI.Ink(f.pageTitle)
    local rule = f:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("TOPLEFT", 30, -104)
    rule:SetPoint("TOPRIGHT", -30, -104)
    rule:SetHeight(1)
    rule:SetColorTexture(0.2, 0.12, 0.04, 0.8)

    f.pageArea = CreateFrame("Frame", nil, f)
    f.pageArea:SetPoint("TOPLEFT", 30, -116)
    f.pageArea:SetPoint("BOTTOMRIGHT", -30, 48)

    -- pied de page : choix de la langue
    local langLabel = UI.Label(f, L["Language"])
    langLabel:SetPoint("BOTTOMRIGHT", -214, 20)
    local lang = CreateFrame("Frame", "iMorphRackLangDropDown", f, "UIDropDownMenuTemplate")
    lang:SetPoint("BOTTOMRIGHT", -14, 10)
    UIDropDownMenu_SetWidth(lang, 170)
    UIDropDownMenu_Initialize(lang, function()
        for _, o in ipairs(LANGUAGES) do
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = L[o.text], o.value
            info.checked = (ns.db.lang or "auto") == o.value
            info.func = function()
                CloseDropDownMenus()
                if (ns.db.lang or "auto") ~= o.value then
                    StaticPopupDialogs.IMORPHRACK_RELOAD.text = L["The interface will be reloaded to apply the language."]
                    StaticPopup_Show("IMORPHRACK_RELOAD", nil, nil, o.value) end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    for _, o in ipairs(LANGUAGES) do
        if o.value == (ns.db.lang or "auto") then UIDropDownMenu_SetText(lang, L[o.text]) end
    end

    local valid = false
    for _, t in ipairs(ns.PAGES) do if t.key == ns.db.tab then valid = true end end
    SelectTab(valid and ns.db.tab or ns.PAGES[1].key)

    -- avertissement si iMorph.exe n'est pas injecté
    local warn = CreateFrame("Frame", nil, f, "BackdropTemplate")
    warn:SetPoint("TOPLEFT", 10, -62)
    warn:SetPoint("BOTTOMRIGHT", -10, 10)
    warn:SetFrameLevel(f:GetFrameLevel() + 50)
    warn:EnableMouse(true) -- bloque les clics sur l'addon derrière
    warn:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    local icon = warn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(64, 64)
    icon:SetPoint("CENTER", 0, 80)
    icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    local title = warn:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -12)
    title:SetText(L["iMorph is not running"])
    local msg = warn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    msg:SetPoint("TOP", title, "BOTTOM", 0, -12)
    msg:SetWidth(UI.WIDTH - 160)
    msg:SetText(L["Launch iMorph and inject it into the game, then the commands will work. This window will disappear on its own."])
    local ignore = UI.Button(warn, L["Continue anyway"], 180, 24, function() warn.ignored = true; warn:Hide() end)
    ignore:SetPoint("TOP", msg, "BOTTOM", 0, -24)

    local function Check()
        warn:SetShown(not ns.IsInjected() and not warn.ignored)
    end
    local t = 0
    f:HookScript("OnUpdate", function(_, e)
        t = t + e
        if t > 1 then t = 0; Check() end
    end)
    f:HookScript("OnShow", Check)
    Check()
end

function ns.Toggle()
    if not main then Build() main:Show() return end
    main:SetShown(not main:IsShown())
end
