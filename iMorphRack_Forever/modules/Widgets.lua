-- iMorph Rack (Forever) : widgets partagés, construits sur le skin personnalisé (Core/Skin.lua)
local _, ns = ...
local L, S = ns.L, ns.Skin
local C = S.C

local UI = {}
ns.UI = UI
UI.WIDTH, UI.HEIGHT = 720, 600
UI.PAGE_W = UI.WIDTH - 40           -- largeur de la zone des pages
UI.PAGE_H = UI.HEIGHT - 92 - 46      -- hauteur de la zone des pages
UI.COL2 = 350             -- x de la deuxième colonne

function UI.Button(parent, text, w, h, onClick, primary)
    return S.Button(parent, text, w or 100, h or 24, onClick, primary)
end

function UI.EditBox(parent, w, placeholder, h)
    return S.EditBox(parent, w or 80, h or 22, placeholder)
end

-- texte : taille, couleur de la palette ("text", "muted", "gold", "accent"...)
function UI.Label(parent, text, size, col)
    local fs = S.Text(parent, size or 13, col or "text")
    fs:SetText(text or "")
    return fs
end

-- titre de section (largeur w, par défaut jusqu'au bord droit de la page)
function UI.Heading(parent, text, x, y, w)
    local h = S.Section(parent, text)
    h:SetPoint("TOPLEFT", x, y)
    h:SetWidth(w or (UI.PAGE_W - x))
    return h
end

-- ligne "libellé + champ + Appliquer"
function UI.CommandRow(parent, x, y, label, build)
    local l = UI.Label(parent, label, 12)
    l:SetPoint("TOPLEFT", x, y)
    S.FitText(l, 136, 12)
    local e = UI.EditBox(parent, 100)
    e:SetPoint("TOPLEFT", x + 142, y + 5)
    local apply = function()
        local v = strtrim(e:GetText())
        if v ~= "" then ns.Run(build(v)); e:ClearFocus() end
    end
    e:SetScript("OnEnterPressed", apply)
    UI.Button(parent, L["Apply"], 84, 22, apply):SetPoint("LEFT", e, "RIGHT", 8, 0)
    return e
end

-- cadre sombre arrondi pour les listes
function UI.ListBox(parent)
    local box = CreateFrame("Frame", nil, parent)
    S.Rounded(box, 8, C.well, { 0.02, 0.035, 0.06, 1 }, C.trim)
    return box
end

-- infobulle simple sur un cadre (lignes : texte ou {texte, r, g, b})
function UI.Tooltip(frame, ...)
    local lines = { ... }
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        for i, l in ipairs(lines) do
            local t = type(l) == "function" and l() or l
            if type(t) == "table" then GameTooltip:AddLine(t[1], t[2], t[3], t[4], true)
            elseif i == 1 then GameTooltip:AddLine(t)
            else GameTooltip:AddLine(t, 1, 1, 1, true) end
        end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", GameTooltip_Hide)
end

-- Boîte de dialogue (confirmation / saisie), au style de l'addon --------------------
local dialog
local function Dialog()
    if dialog then return dialog end
    local d = S.Window("iMorphRackDialog", UIParent, 400, 150, "iMorph Rack")
    d:SetFrameStrata("FULLSCREEN_DIALOG")
    d:SetToplevel(true)
    d:SetPoint("CENTER", 0, 140)
    d:Hide()
    S.Draggable(d, d.titleBar)
    tinsert(UISpecialFrames, "iMorphRackDialog")

    d.msg = S.Text(d, 13, "text")
    d.msg:SetPoint("TOPLEFT", 20, -52)
    d.msg:SetPoint("TOPRIGHT", -20, -52)
    d.msg:SetJustifyH("CENTER")

    d.input = S.EditBox(d, 360, 24)
    d.input:SetPoint("TOP", d.msg, "BOTTOM", 0, -12)
    d.input:SetMaxLetters(0)

    d.ok = S.Button(d, OKAY, 130, 24, function()
        local cb, v = d.onAccept, d.input:GetText()
        d.onAccept = nil
        S.Close(d)
        if cb then cb(v) end
    end, true)
    d.ok:SetPoint("BOTTOMRIGHT", d, "BOTTOM", -6, 16)
    d.cancel = S.Button(d, CANCEL, 130, 24, function() d.onAccept = nil; S.Close(d) end)
    d.cancel:SetPoint("BOTTOMLEFT", d, "BOTTOM", 6, 16)
    -- texte verrouillé (lien à copier) : la saisie ne peut pas le modifier
    d.input:HookScript("OnTextChanged", function(self)
        if d.locked and self:GetText() ~= d.locked then
            self:SetText(d.locked)
            self:HighlightText()
        end
    end)
    d.input:SetScript("OnEnterPressed", function() d.ok:Click() end)
    d.input:SetScript("OnEscapePressed", function() d.cancel:Click() end)
    dialog = d
    return d
end

-- opts = { input = true, text = "texte initial", ok = "libellé", noCancel = true, locked = true }
function UI.Dialog(message, onAccept, opts)
    opts = opts or {}
    local d = Dialog()
    d.onAccept = onAccept
    d.msg:SetText(message)
    d.input:SetShown(opts.input and true or false)
    d.locked = nil
    d.input:SetText(opts.text or "")
    d.locked = opts.locked and (opts.text or "") or nil
    d.ok:SetText(opts.ok or OKAY)
    d.cancel:SetShown(not opts.noCancel)
    d.ok:ClearAllPoints()
    if opts.noCancel then d.ok:SetPoint("BOTTOM", 0, 16)
    else d.ok:SetPoint("BOTTOMRIGHT", d, "BOTTOM", -6, 16) end
    d:SetHeight(110 + d.msg:GetStringHeight() + (opts.input and 36 or 0))
    S.StopTween(d)
    d:SetAlpha(1)
    if d:IsShown() then S.AnimateOpen(d) else d:Show() end
    if opts.input then
        d.input:SetFocus()
        d.input:HighlightText()
    end
end

function UI.Confirm(message, onAccept) UI.Dialog(message, onAccept) end

-- Signaler un bug : le jeu ne peut pas ouvrir de lien, l'invitation Discord est affichée sélectionnée
ns.DISCORD = "https://discord.com/invite/2WXxyC84NJ"
function ns.ReportBug()
    UI.Dialog(L["Report a bug on Discord: press Ctrl+C to copy the link."], nil,
        { input = true, text = ns.DISCORD, ok = CLOSE, noCancel = true, locked = true })
end

-- petit bouton de barre de titre qui ouvre le signalement de bug
function UI.BugButton(parent)
    local b = S.Button(parent, L["Bug"], 34, 20, ns.ReportBug)
    b:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(L["Report a bug"], 1, 1, 1)
        GameTooltip:AddLine(L["Copy the link of the Discord server"], 0.5, 1, 0.5)
        GameTooltip:Show()
    end)
    b:HookScript("OnLeave", GameTooltip_Hide)
    return b
end

-- menu des thèmes : skin Forever (par défaut) ou interface Blizzard Forever ; rechargement
function UI.ThemeSelector(parent)
    local options = {
        { "default", "Forever", L["Forever (default)"] },
        { "blizzard", "Blizzard Forever", "Blizzard Forever" },
    }
    return S.Dropdown(parent, 130, 180, options, function() return ns.db.theme or "default" end, function(v)
        if (ns.db.theme or "default") == v then return end
        UI.Confirm(L["The interface will be reloaded to apply the theme."], function()
            ns.db.theme = v
            ReloadUI()
        end)
    end, { tooltip = L["Theme"] })
end

-- menu des langues (Auto + chaque langue) ; changer de langue demande un rechargement
UI.LANGS = {
    { "enUS", "EN", "English" },
    { "frFR", "FR", "Français" },
}
function UI.LanguageSelector(parent)
    local options = { { "auto", L["Auto"], L["Automatic (game language)"] } }
    for _, l in ipairs(UI.LANGS) do options[#options + 1] = { l[1], l[2], l[3] } end
    return S.Dropdown(parent, 52, 180, options, function() return ns.db.lang or "auto" end, function(v)
        if (ns.db.lang or "auto") == v then return end
        UI.Confirm(L["The interface will be reloaded to apply the language."], function()
            ns.db.lang = v
            ReloadUI()
        end)
    end, { tooltip = L["Language"] })
end
function UI.Prompt(message, text, onAccept) UI.Dialog(message, onAccept, { input = true, text = text }) end
