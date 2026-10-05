-- iMorph Rack (Forever) : widgets partagés
-- Même style que Alt Dashboard (Forever) : cadre du grimoire, portrait, parchemin, onglets icônes
local _, ns = ...
local L = ns.L

local UI = {}
ns.UI = UI
UI.WIDTH, UI.HEIGHT = 720, 600
UI.COL2 = 340 -- x de la deuxième colonne (page de droite)

function UI.Ink(fs)
    fs:SetTextColor(0.1, 0.05, 0.01)
    fs:SetShadowOffset(0, 0)
    return fs
end

function UI.Button(parent, text, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or 100, h or 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

function UI.EditBox(parent, w)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(w or 80, 20)
    e:SetAutoFocus(false)
    e:SetScript("OnEscapePressed", e.ClearFocus)
    return e
end

function UI.Label(parent, text, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    fs:SetText(text)
    return UI.Ink(fs)
end

function UI.Heading(parent, text, x, y)
    local fs = UI.Label(parent, text, "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", x, y)
    return fs
end

-- Ligne "libellé + champ + Appliquer"
function UI.CommandRow(parent, x, y, label, build)
    local l = UI.Label(parent, label, "GameFontNormal")
    l:SetPoint("TOPLEFT", x, y)
    local e = UI.EditBox(parent, 90)
    e:SetPoint("TOPLEFT", x + 140, y + 4)
    local apply = function()
        local v = strtrim(e:GetText())
        if v ~= "" then ns.Run(build(v)); e:ClearFocus() end
    end
    e:SetScript("OnEnterPressed", apply)
    UI.Button(parent, L["Apply"], 80, 22, apply):SetPoint("LEFT", e, "RIGHT", 8, 0)
    return e
end

-- cadre sombre à bordure dorée pour les listes
function UI.ListBox(parent)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0.04, 0.03, 0.02, 0.9)
    box:SetBackdropBorderColor(0.6, 0.5, 0.2, 0.8)
    return box
end
