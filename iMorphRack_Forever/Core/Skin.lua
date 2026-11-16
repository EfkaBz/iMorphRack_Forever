-- iMorph Rack (Forever) : skin entièrement personnalisé (aucun modèle Blizzard)
-- fenêtres arrondies en 9-slice, halo, lueur intérieure, animations (ouverture/fermeture,
-- survols en fondu, menus déroulants, onglets), boutons, champs, barres de défilement
local ADDON, ns = ...

local S = {}
ns.Skin = S

local WHITE = "Interface\\Buttons\\WHITE8x8"
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\adds\\UI\\"
S.MEDIA = MEDIA

-- Palette (tirée de l'icône : halo cyan, lettres or, fond nuit) ------------------
local function hex(h)
    return { tonumber(h:sub(2, 3), 16) / 255, tonumber(h:sub(4, 5), 16) / 255, tonumber(h:sub(6, 7), 16) / 255, 1 }
end

local C = {
    bg1      = hex("#0E1B2F"), -- dégradé de fenêtre, haut
    bg2      = hex("#05090F"), -- dégradé de fenêtre, bas
    well     = hex("#070C15"), -- intérieur des champs et listes
    trim     = hex("#2A6A96"), -- bordures
    ring     = hex("#3FC6FF"), -- bordure active / survol
    accent   = hex("#4FD2FF"), -- cyan de l'icône
    gold     = hex("#FFC23C"), -- or des lettres de l'icône
    text     = hex("#E6EEF8"),
    muted    = hex("#8193AD"),
    good     = hex("#6BDB8B"),
    bad      = hex("#FF6B6B"),
    btn1     = hex("#15263D"), btn2 = hex("#0A1220"),
    primary1 = hex("#2B7DB4"), primary2 = hex("#123C63"),
    pill1    = hex("#1F5A8F"), pill2 = hex("#0E2745"),
}
S.C = C

local function color(t, a) return t[1], t[2], t[3], a or t[4] end
S.Color = color

local function lerp(a, b, p) return a + (b - a) * p end
local function lerpColor(c1, c2, p)
    return lerp(c1[1], c2[1], p), lerp(c1[2], c2[2], p), lerp(c1[3], c2[3], p), lerp(c1[4] or 1, c2[4] or 1, p)
end

-- dégradé c1 -> c2, de haut en bas (ou de gauche à droite si horizontal)
local function gradient(tex, c1, c2, horizontal, keepTexture)
    if not keepTexture then tex:SetTexture(WHITE) end
    tex:SetVertexColor(1, 1, 1, 1)
    local o = horizontal and "HORIZONTAL" or "VERTICAL"
    local a, b = c1, c2
    if not horizontal then a, b = c2, c1 end -- VERTICAL va de bas en haut
    if tex.SetGradient then
        local function col(c) return { r = c[1], g = c[2], b = c[3], a = c[4] or 1 } end
        if pcall(tex.SetGradient, tex, o, col(a), col(b)) then return end
    end
    if tex.SetGradientAlpha and pcall(tex.SetGradientAlpha, tex, o,
        a[1], a[2], a[3], a[4] or 1, b[1], b[2], b[3], b[4] or 1) then return end
    tex:SetVertexColor(color(c1))
end
S.Gradient = gradient

-- Animations ---------------------------------------------------------------------
local ease = {
    linear = function(p) return p end,
    outCubic = function(p) return 1 - (1 - p) ^ 3 end,
    inOutCubic = function(p) return p < 0.5 and 4 * p ^ 3 or 1 - (-2 * p + 2) ^ 3 / 2 end,
    outBack = function(p) local c = 1.70158; return 1 + (c + 1) * (p - 1) ^ 3 + c * (p - 1) ^ 2 end,
}
S.Ease = ease

local tweens, running = {}, {}
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(self, elapsed)
    wipe(running)
    for key, t in pairs(tweens) do running[key] = t end
    for key, t in pairs(running) do
        if tweens[key] == t then
            t.t = t.t + elapsed
            local p = math.min(1, t.t / t.dur)
            t.set(lerp(t.from, t.to, t.ease(p)), p)
            if p >= 1 and tweens[key] == t then
                tweens[key] = nil
                if t.done then t.done() end
            end
        end
    end
    if not next(tweens) then self:Hide() end
end)

-- S.Tween(clé, { dur, from, to, ease, set(valeur, p), done }) ; même clé = remplace
function S.Tween(key, a)
    a.t, a.dur = 0, a.dur or 0.25
    a.ease = type(a.ease) == "function" and a.ease or ease[a.ease or "outCubic"]
    tweens[key] = a
    driver:Show()
end
function S.StopTween(key) tweens[key] = nil end
function S.IsTweening(key) return tweens[key] ~= nil end

function S.FadeTo(region, alpha, dur, done)
    S.Tween(region, { dur = dur or 0.15, from = region:GetAlpha(), to = alpha,
        set = function(v) region:SetAlpha(v) end, done = done })
end

-- Police (celle du jeu, avec une ombre douce) ------------------------------------
local fonts = {}
local function font(size)
    if not fonts[size] then
        local f = CreateFont("iMorphRackFont" .. size)
        f:SetFont(STANDARD_TEXT_FONT, size, "")
        f:SetShadowColor(0, 0, 0, 0.9)
        f:SetShadowOffset(1, -1)
        fonts[size] = f
    end
    return fonts[size]
end
S.Font = font

function S.Text(parent, size, col, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFontObject(font(size or 13))
    fs:SetTextColor(color(C[col or "text"]))
    fs:SetJustifyH("LEFT")
    return fs
end

-- fait tenir un texte d'une ligne dans une largeur : police réduite jusqu'à 9, puis "..."
function S.FitText(fs, maxWidth, size)
    local r, g, b, a = fs:GetTextColor()
    fs:SetWidth(0)
    for s = size, 9, -1 do
        fs:SetFontObject(font(s))
        if fs:GetStringWidth() <= maxWidth then
            fs:SetTextColor(r, g, b, a)
            return
        end
    end
    fs:SetTextColor(r, g, b, a)
    fs:SetWordWrap(false)
    fs:SetWidth(maxWidth)
end

-- Cadres ---------------------------------------------------------------------------
local function setBorderColor(f, r, g, b, a)
    for _, t in ipairs(f.borders) do
        if t.isCorner then t:SetVertexColor(r, g, b, a or 1) else t:SetColorTexture(r, g, b, a or 1) end
    end
end

-- bordure qui glisse en douceur vers une couleur
function S.TintBorder(f, to, dur)
    local from = f.borderNow or f.borderBase
    S.Tween(f.borders, { dur = dur or 0.18, from = 0, to = 1, set = function(v)
        local r, g, b, a = lerpColor(from, to, v)
        f.borderNow = { r, g, b, a }
        f:SetBorderColor(r, g, b, a)
    end })
end

local function frameLines(f, layer, sub)
    local t, b, l, r = f:CreateTexture(nil, layer, nil, sub), f:CreateTexture(nil, layer, nil, sub),
        f:CreateTexture(nil, layer, nil, sub), f:CreateTexture(nil, layer, nil, sub)
    t:SetPoint("TOPLEFT"); t:SetPoint("TOPRIGHT"); t:SetHeight(1)
    b:SetPoint("BOTTOMLEFT"); b:SetPoint("BOTTOMRIGHT"); b:SetHeight(1)
    l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT"); l:SetWidth(1)
    r:SetPoint("TOPRIGHT"); r:SetPoint("BOTTOMRIGHT"); r:SetWidth(1)
    return { t, b, l, r }
end

-- boîte carrée : fond (couleur ou dégradé {haut, bas}) + bordure 1 px
function S.Box(f, bg, border)
    f.bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    f.bg:SetAllPoints()
    if bg and type(bg[1]) == "table" then gradient(f.bg, bg[1], bg[2])
    else f.bg:SetColorTexture(color(bg or C.well)) end
    if border ~= false then
        f.borders = frameLines(f, "BORDER", 0)
        f.SetBorderColor = setBorderColor
        f.borderBase = border or C.trim
        f:SetBorderColor(color(f.borderBase))
    end
    return f
end

-- 9-slice : texture carrée avec des coins de `margin` px (sur `size`), coins dessinés à `cs` px
local POINTS = {
    { "TOPLEFT", "TOP" }, { "TOP", "TOP" }, { "TOPRIGHT", "TOP" },
    { "LEFT", "MID" }, { "CENTER", "MID" }, { "RIGHT", "MID" },
    { "BOTTOMLEFT", "BOTTOM" }, { "BOTTOM", "BOTTOM" }, { "BOTTOMRIGHT", "BOTTOM" },
}
local function slice9(f, file, size, margin, cs, layer, sub)
    local m = margin / size
    local u = { 0, m, 1 - m, 1 }
    local tex = {}
    for i, p in ipairs(POINTS) do
        local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
        local t = f:CreateTexture(nil, layer, nil, sub)
        t:SetTexture(file)
        t:SetTexCoord(u[col + 1], u[col + 2], u[row + 1], u[row + 2])
        t.row = p[2]
        tex[p[1]] = t
    end
    for _, k in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
        tex[k]:SetSize(cs, cs); tex[k]:SetPoint(k)
    end
    tex.TOP:SetPoint("TOPLEFT", tex.TOPLEFT, "TOPRIGHT"); tex.TOP:SetPoint("BOTTOMRIGHT", tex.TOPRIGHT, "BOTTOMLEFT")
    tex.BOTTOM:SetPoint("TOPLEFT", tex.BOTTOMLEFT, "TOPRIGHT"); tex.BOTTOM:SetPoint("BOTTOMRIGHT", tex.BOTTOMRIGHT, "BOTTOMLEFT")
    tex.LEFT:SetPoint("TOPLEFT", tex.TOPLEFT, "BOTTOMLEFT"); tex.LEFT:SetPoint("BOTTOMRIGHT", tex.BOTTOMLEFT, "TOPRIGHT")
    tex.RIGHT:SetPoint("TOPLEFT", tex.TOPRIGHT, "BOTTOMLEFT"); tex.RIGHT:SetPoint("BOTTOMRIGHT", tex.BOTTOMRIGHT, "TOPRIGHT")
    tex.CENTER:SetPoint("TOPLEFT", tex.TOPLEFT, "BOTTOMRIGHT"); tex.CENTER:SetPoint("BOTTOMRIGHT", tex.BOTTOMRIGHT, "TOPLEFT")
    return tex
end

-- halo doux autour d'un cadre
function S.Shadow(f, size, alpha, col)
    size = size or 14
    local holder = CreateFrame("Frame", nil, f)
    holder:SetPoint("TOPLEFT", -size, size)
    holder:SetPoint("BOTTOMRIGHT", size, -size)
    holder:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
    col = col or { 0, 0, 0 }
    for _, t in pairs(slice9(holder, MEDIA .. "Shadow", 64, 16, size * 1.6, "BACKGROUND", -8)) do
        t:SetVertexColor(col[1], col[2], col[3], alpha or 0.7)
    end
    f.shadow = holder
    return holder
end

-- boîte arrondie (rayon r) : dégradé vertical + bordure 1 px
function S.Rounded(f, r, top, bottom, border)
    r, top, bottom = r or 12, top or C.bg1, bottom or C.bg2
    local cs = r * 16 / 12
    for _, t in pairs(slice9(f, MEDIA .. "RoundFill", 64, 16, cs, "BACKGROUND", -7)) do
        if t.row == "TOP" then t:SetVertexColor(color(top))
        elseif t.row == "BOTTOM" then t:SetVertexColor(color(bottom))
        else gradient(t, top, bottom, false, true) end
    end
    f.borders = {}
    for _, t in pairs(slice9(f, MEDIA .. "RoundEdge", 64, 16, cs, "BORDER", 1)) do
        t.isCorner = true
        f.borders[#f.borders + 1] = t
    end
    f.SetBorderColor = setBorderColor
    f.borderBase = border or C.trim
    f:SetBorderColor(color(f.borderBase))
    return f
end

-- lumière cyan le long des bords intérieurs, qui respire lentement
function S.EdgeGlow(f, depth, alpha)
    depth, alpha = depth or 48, alpha or 0.2
    local pieces = slice9(f, MEDIA .. "RoundGlow", 128, 48, depth, "BACKGROUND", -5)
    for _, t in pairs(pieces) do t:SetVertexColor(0.25, 0.75, 1, alpha) end
    local d = CreateFrame("Frame", nil, f)
    local clock = math.random() * 6
    d:SetScript("OnUpdate", function(_, elapsed)
        clock = clock + elapsed
        local a = 0.85 + 0.15 * math.sin(clock * 1.6)
        for _, t in pairs(pieces) do t:SetAlpha(a) end
    end)
end

-- ligne qui s'efface des deux côtés
function S.Rule(parent, col, alpha)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(1)
    local c1, c2 = { col[1], col[2], col[3], 0 }, { col[1], col[2], col[3], alpha or 1 }
    local l = holder:CreateTexture(nil, "ARTWORK")
    l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMRIGHT", holder, "BOTTOM")
    gradient(l, c1, c2, true)
    local r = holder:CreateTexture(nil, "ARTWORK")
    r:SetPoint("TOPLEFT", holder, "TOP"); r:SetPoint("BOTTOMRIGHT")
    gradient(r, c2, c1, true)
    return holder
end

-- icône avec un liseré fin et un vernis
function S.Icon(parent, size, layer)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(size, size)
    S.Box(holder, { 0, 0, 0, 1 }, C.trim)
    local tex = holder:CreateTexture(nil, layer or "ARTWORK")
    tex:SetPoint("TOPLEFT", 1, -1)
    tex:SetPoint("BOTTOMRIGHT", -1, 1)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    holder.tex = tex
    local gloss = holder:CreateTexture(nil, "OVERLAY")
    gloss:SetAllPoints(tex)
    gloss:SetTexture(MEDIA .. "Gloss")
    return holder
end

-- survol doux : une région apparaît / disparaît en fondu
-- (les appelants posent leurs propres OnEnter / OnLeave avec HookScript)
function S.HoverFade(frame, region, alpha)
    region:SetAlpha(0)
    frame:HookScript("OnEnter", function() S.FadeTo(region, alpha or 1, 0.12) end)
    frame:HookScript("OnLeave", function() S.FadeTo(region, 0, 0.25) end)
end

-- surbrillance de ligne : voile cyan vers la droite + barre dorée à gauche
function S.RowHighlight(row)
    local hl = CreateFrame("Frame", nil, row)
    hl:SetAllPoints()
    local wash = hl:CreateTexture(nil, "BACKGROUND", nil, 1)
    wash:SetAllPoints()
    gradient(wash, { 0.3, 0.8, 1, 0.16 }, { 0.3, 0.8, 1, 0 }, true)
    local bar = hl:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT"); bar:SetPoint("BOTTOMLEFT"); bar:SetWidth(2)
    bar:SetColorTexture(color(C.gold))
    S.HoverFade(row, hl)
    return hl
end

-- chevron dessiné avec deux traits tournés (la police du jeu n'a pas de flèche)
function S.Chevron(parent, col)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(12, 8)
    local function bar(x)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetTexture(WHITE)
        t:SetSize(6, 1.6)
        t:SetPoint("CENTER", x, 0)
        t:SetVertexColor(color(col or C.gold))
        return t
    end
    local l, r = bar(-2.2), bar(2.2)
    local angle = 40
    function f:SetAngle(a)
        angle = a
        l:SetRotation(math.rad(-a))
        r:SetRotation(math.rad(a))
    end
    -- up = pointe vers le haut
    function f:Flip(up, instant)
        local to = up and -40 or 40
        if instant then S.StopTween(f); f:SetAngle(to) return end
        S.Tween(f, { dur = 0.2, from = angle, to = to, set = function(v) f:SetAngle(v) end })
    end
    f:SetAngle(40)
    return f
end

-- Bouton de fermeture : x discret, lueur rouge au survol ----------------------------
function S.CloseButton(parent, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(22, 22)
    b:SetScript("OnEnter", function(self) self.x:SetTextColor(color(C.gold)) end)
    b:SetScript("OnLeave", function(self) self.x:SetTextColor(color(C.muted)) end)
    local glow = b:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture(MEDIA .. "Glow")
    glow:SetPoint("CENTER")
    glow:SetSize(30, 30)
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 0.35, 0.35, 0.5)
    S.HoverFade(b, glow)
    b.x = S.Text(b, 15, "muted")
    b.x:SetPoint("CENTER", 0, 1)
    b.x:SetText("x")
    b:SetScript("OnClick", onClick or function() S.AnimateClose(parent) end)
    return b
end

-- Fenêtres -------------------------------------------------------------------------
-- ouverture : fondu + petite montée avec léger rebond
function S.AnimateOpen(f, dx, dy)
    local p, rel, rp, x, y = f:GetPoint(1)
    if not p then return end
    f.home = f.home or { p, rel, rp, x, y }
    local h = f.home
    dx, dy = dx or 0, dy or -12
    f:SetAlpha(0)
    S.Tween(f, { dur = 0.32, from = 0, to = 1, ease = "outBack", set = function(v, pr)
        f:SetAlpha(math.min(1, pr * 2.5))
        f:ClearAllPoints()
        f:SetPoint(h[1], h[2], h[3], h[4] + dx * (1 - v), h[5] + dy * (1 - v))
    end })
end

-- fermeture rapide en fondu
function S.Close(f)
    if not f:IsShown() then return end
    S.Tween(f, { dur = 0.14, from = f:GetAlpha(), to = 0, set = function(v) f:SetAlpha(v) end,
        done = function() f:Hide(); f:SetAlpha(1) end })
end

-- fermeture inverse de l'ouverture : glisse et s'efface, puis se cache
function S.AnimateClose(f, dx, dy)
    if not f:IsShown() then return end
    local p, rel, rp, x, y = f:GetPoint(1)
    f.home = f.home or { p, rel, rp, x, y }
    local h = f.home
    dx, dy = dx or 0, dy or -12
    local a0 = f:GetAlpha()
    S.Tween(f, { dur = 0.2, from = 0, to = 1, ease = "inOutCubic", set = function(v)
        f:SetAlpha(a0 * (1 - v))
        f:ClearAllPoints()
        f:SetPoint(h[1], h[2], h[3], h[4] + dx * v, h[5] + dy * v)
    end, done = function()
        f:Hide()
        f:SetAlpha(1)
        f:ClearAllPoints()
        f:SetPoint(h[1], h[2], h[3], h[4], h[5])
    end })
end

-- fenêtre arrondie en dégradé, halo, barre de titre avec un filet cyan
function S.Window(name, parent, width, height, title)
    local f = CreateFrame("Frame", name, parent or UIParent)
    f:SetSize(width, height)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    S.Shadow(f, 16, 0.45, { 0.1, 0.55, 0.95 })
    S.Rounded(f, 12)
    S.EdgeGlow(f, 48, 0.16)

    local bar = CreateFrame("Frame", nil, f)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(38)
    f.titleBar = bar
    local rule = S.Rule(bar, C.ring, 0.9)
    rule:SetPoint("BOTTOMLEFT", 10, 0)
    rule:SetPoint("BOTTOMRIGHT", -10, 0)

    f.title = S.Text(bar, 16, "gold")
    f.title:SetPoint("LEFT", 14, 0)
    f.title:SetText(title or "")

    f.close = S.CloseButton(f)
    f.close:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
    f.close:SetFrameLevel(bar:GetFrameLevel() + 5)
    f:HookScript("OnShow", function(self) S.AnimateOpen(self) end)
    return f
end

-- rend un cadre déplaçable par une poignée
function S.Draggable(f, handle, onStop)
    f:SetMovable(true)
    handle = handle or f
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function() S.StopTween(f); f:SetAlpha(1); f:StartMoving() end)
    handle:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local p, rel, rp, x, y = f:GetPoint(1)
        f.home = { p, rel, rp, x, y }
        if onStop then onStop(f) end
    end)
end

-- titre de section : point doré, libellé, texte à droite, filet qui s'efface
function S.Section(parent, text)
    local h = CreateFrame("Frame", nil, parent)
    h:SetHeight(22)
    local dot = h:CreateTexture(nil, "ARTWORK")
    dot:SetSize(4, 4)
    dot:SetPoint("LEFT", 0, 2)
    dot:SetColorTexture(color(C.gold))
    h.label = S.Text(h, 13, "gold")
    h.label:SetPoint("LEFT", dot, "RIGHT", 7, 2)
    h.label:SetText(text or "")
    h.right = S.Text(h, 11, "muted")
    h.right:SetPoint("RIGHT", 0, 2)
    local line = h:CreateTexture(nil, "BORDER")
    line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(1)
    gradient(line, { C.ring[1], C.ring[2], C.ring[3], 0.7 }, { C.ring[1], C.ring[2], C.ring[3], 0 }, true)
    return h
end

-- Boutons --------------------------------------------------------------------------
-- dégradé + vernis ; survol = la bordure glisse vers le cyan + lueur intérieure
function S.Button(parent, text, width, height, onClick, primary)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 120, height or 24)
    S.Box(b, primary and { C.primary1, C.primary2 } or { C.btn1, C.btn2 }, primary and C.ring or C.trim)
    local gloss = b:CreateTexture(nil, "ARTWORK", nil, 1)
    gloss:SetPoint("TOPLEFT", 1, -1); gloss:SetPoint("BOTTOMRIGHT", -1, 1)
    gloss:SetTexture(MEDIA .. "Gloss")
    local glow = b:CreateTexture(nil, "ARTWORK", nil, 2)
    glow:SetPoint("TOPLEFT", 1, -1); glow:SetPoint("BOTTOMRIGHT", -1, 1)
    gradient(glow, { 0.3, 0.8, 1, 0 }, { 0.3, 0.8, 1, primary and 0.32 or 0.2 })
    glow:SetBlendMode("ADD")
    S.HoverFade(b, glow)

    b.text = S.Text(b, 12, primary and "gold" or "text")
    b.text:SetPoint("CENTER")
    b.text:SetJustifyH("CENTER")
    b.fitWidth = (width or 120) - 8
    b.text:SetText(text or "")
    S.FitText(b.text, b.fitWidth, 12)
    b:HookScript("OnEnter", function(self) if self:IsEnabled() then S.TintBorder(self, C.gold) end end)
    b:HookScript("OnLeave", function(self) S.TintBorder(self, self.borderBase) end)
    b:SetScript("OnMouseDown", function(self) if self:IsEnabled() then self.text:SetPoint("CENTER", 0, -1) end end)
    b:SetScript("OnMouseUp", function(self) self.text:SetPoint("CENTER") end)
    b:SetScript("OnClick", onClick)
    function b:SetText(t)
        self.text:SetText(t)
        S.FitText(self.text, self.fitWidth, 12)
    end
    hooksecurefunc(b, "SetEnabled", function(self, on) self:SetAlpha(on and 1 or 0.45) end)
    return b
end

-- Champ de saisie ------------------------------------------------------------------
-- puits sombre, bordure qui s'allume au focus, lueur intérieure, texte d'aide
function S.EditBox(parent, width, height, placeholder)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetSize(width or 80, height or 22)
    e:SetAutoFocus(false)
    e:SetFontObject(font(12))
    e:SetTextColor(color(C.text))
    e:SetTextInsets(6, 6, 0, 0)
    S.Box(e, C.well, C.trim)
    local glow = e:CreateTexture(nil, "BORDER", nil, -1)
    glow:SetPoint("TOPLEFT", 1, -1); glow:SetPoint("BOTTOMRIGHT", -1, 1)
    gradient(glow, { 0.3, 0.8, 1, 0 }, { 0.3, 0.8, 1, 0.16 })
    glow:SetAlpha(0)

    e.hint = S.Text(e, 12, "muted")
    e.hint:SetPoint("LEFT", 7, 0)
    e.hint:SetPoint("RIGHT", -6, 0)
    e.hint:SetWordWrap(false)
    e.hint:SetText(placeholder or "")
    local function hint() e.hint:SetShown(e:GetText() == "" and not e:HasFocus()) end

    e:SetScript("OnEscapePressed", e.ClearFocus)
    e:SetScript("OnEditFocusGained", function(self) S.FadeTo(glow, 1, 0.15); S.TintBorder(self, C.ring); hint() end)
    e:SetScript("OnEditFocusLost", function(self) S.FadeTo(glow, 0, 0.25); S.TintBorder(self, self.borderBase); hint() end)
    e:SetScript("OnTextChanged", hint)
    e:SetScript("OnEnter", function(self) if not self:HasFocus() then S.TintBorder(self, C.accent) end end)
    e:SetScript("OnLeave", function(self) if not self:HasFocus() then S.TintBorder(self, self.borderBase) end end)
    function e:SetPlaceholder(t) self.hint:SetText(t) end
    hint()
    return e
end

-- Barres de défilement -------------------------------------------------------------
-- barre verticale fine (liste virtuelle) : onChange(offset)
function S.ScrollBar(parent, onChange)
    local bar = CreateFrame("Slider", nil, parent)
    bar:SetOrientation("VERTICAL")
    bar:SetWidth(5)
    bar:SetValueStep(1)
    if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(true) end
    bar:SetHitRectInsets(-4, -4, 0, 0)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0, 0, 0, 0.5)
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE)
    thumb:SetSize(5, 30)
    thumb:SetVertexColor(color(C.trim))
    bar:SetThumbTexture(thumb)
    bar:SetMinMaxValues(0, 0)
    bar:SetValue(0)
    bar:SetScript("OnValueChanged", function(_, v) onChange(math.floor(v + 0.5)) end)
    bar:SetScript("OnEnter", function() thumb:SetVertexColor(color(C.accent)) end)
    bar:SetScript("OnLeave", function() thumb:SetVertexColor(color(C.trim)) end)
    -- max : dernier décalage possible ; visible / total : taille du curseur
    function bar:SetRange(max, visible, total)
        self:SetMinMaxValues(0, math.max(0, max))
        self:SetShown(max > 0)
        local h = self:GetHeight()
        if h > 0 and total > 0 then thumb:SetHeight(math.max(20, h * visible / total)) end
    end
    return bar
end

-- cadre défilant à barre fine et molette douce ; renvoie le cadre et son contenu
function S.Scroll(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(1, 1)
    sf:SetScrollChild(content)

    local bar = CreateFrame("Slider", nil, parent)
    bar:SetOrientation("VERTICAL")
    bar:SetWidth(4)
    bar:SetPoint("TOPLEFT", sf, "TOPRIGHT", 4, -2)
    bar:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 4, 2)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0, 0, 0, 0.5)
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE)
    thumb:SetSize(4, 30)
    thumb:SetVertexColor(color(C.trim))
    bar:SetThumbTexture(thumb)
    bar:SetMinMaxValues(0, 0)
    bar:SetValue(0)
    bar:SetScript("OnValueChanged", function(_, v) sf:SetVerticalScroll(v) end)
    bar:SetScript("OnEnter", function() thumb:SetVertexColor(color(C.accent)) end)
    bar:SetScript("OnLeave", function() thumb:SetVertexColor(color(C.trim)) end)

    sf:SetScript("OnScrollRangeChanged", function(self)
        local range = self:GetVerticalScrollRange()
        local h = self:GetHeight()
        bar:SetMinMaxValues(0, range)
        bar:SetShown(range > 0)
        if h > 0 then thumb:SetHeight(math.max(20, h * h / (h + range))) end
        if bar:GetValue() > range then bar:SetValue(range) end
    end)
    sf:EnableMouseWheel(true)
    local target = 0
    sf:SetScript("OnMouseWheel", function(_, d)
        local _, hi = bar:GetMinMaxValues()
        target = math.max(0, math.min(hi, (tweens[bar] and target or bar:GetValue()) - d * 60))
        S.Tween(bar, { dur = 0.25, from = bar:GetValue(), to = target, set = function(v) bar:SetValue(v) end })
    end)
    bar:Hide()
    sf.bar = bar
    return sf, content
end

-- Menu déroulant -------------------------------------------------------------------
-- bouton à chevron + menu arrondi qui glisse et apparaît en fondu (défilant si long) ;
-- un clic ailleurs le ferme. options = { {valeur, texte}, ... } ou fonction qui les renvoie
-- opts = { maxRows, up (s'ouvre vers le haut), tooltip }
local MENU_ROW, MENU_PAD = 22, 5
function S.Dropdown(parent, width, menuWidth, getOptions, getValue, onSelect, opts)
    opts = opts or {}
    local maxRows = opts.maxRows or 14
    local b = S.Button(parent, "", width, 22)
    b.text:ClearAllPoints()
    if width < 80 then -- petit bouton (code de langue) : texte centré
        b.fitWidth = width - 22
        b.text:SetPoint("CENTER", -6, 0)
    else
        b.fitWidth = width - 28
        b.text:SetPoint("LEFT", 8, 0)
        b.text:SetJustifyH("LEFT")
    end
    b:SetScript("OnMouseDown", nil)
    b:SetScript("OnMouseUp", nil)
    local chev = S.Chevron(b, C.gold)
    chev:SetPoint("RIGHT", -8, 0)

    local menu, catcher, sf, content
    local rows = {}
    local function options() return type(getOptions) == "function" and getOptions() or getOptions end

    local function close(instant)
        if not menu or not menu:IsShown() then return end
        catcher:Hide()
        chev:Flip(false)
        if instant then
            S.StopTween(menu)
            menu:Hide()
            menu:SetAlpha(1)
        else
            S.Close(menu)
        end
    end

    local function refreshLabel()
        local v = getValue()
        for _, o in ipairs(options()) do
            if o[1] == v then b:SetText(o[2]) return end
        end
        b:SetText("")
    end

    local function refreshRows()
        local v = getValue()
        for _, row in ipairs(rows) do
            local on = row.value == v
            row.dot:SetShown(on)
            row.text:SetTextColor(color(on and C.gold or C.text))
        end
    end

    local function build()
        catcher = CreateFrame("Button", nil, UIParent)
        catcher:SetAllPoints(UIParent)
        catcher:SetFrameStrata("TOOLTIP")
        catcher:SetFrameLevel(10)
        catcher:RegisterForClicks("AnyUp")
        catcher:SetScript("OnClick", function() close() end)
        catcher:Hide()

        menu = CreateFrame("Frame", nil, UIParent)
        menu:SetFrameStrata("TOOLTIP")
        menu:SetFrameLevel(20)
        menu:SetClampedToScreen(true)
        menu:EnableMouse(true)
        S.Shadow(menu, 10, 0.6)
        S.Rounded(menu, 6)
        menu:Hide()
        sf, content = S.Scroll(menu)
        sf:SetPoint("TOPLEFT", MENU_PAD, -MENU_PAD)
        sf:SetPoint("BOTTOMRIGHT", -MENU_PAD - 8, MENU_PAD)
        content:SetWidth(menuWidth - 2 * MENU_PAD - 8)
    end

    local function fill()
        local list = options()
        local w = menuWidth - 2 * MENU_PAD - 8
        for i, o in ipairs(list) do
            local row = rows[i]
            if not row then
                row = CreateFrame("Button", nil, content)
                row:SetHeight(MENU_ROW)
                row:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
                row:SetScript("OnLeave", refreshRows)
                row:SetScript("OnClick", function(self)
                    close()
                    onSelect(self.value)
                    refreshLabel()
                end)
                S.RowHighlight(row)
                row.dot = row:CreateTexture(nil, "OVERLAY")
                row.dot:SetTexture(MEDIA .. "Dot")
                row.dot:SetSize(7, 7)
                row.dot:SetPoint("LEFT", 7, 0)
                row.dot:SetVertexColor(color(C.gold))
                row.text = S.Text(row, 12)
                row.text:SetPoint("LEFT", 20, 0)
                rows[i] = row
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -(i - 1) * MENU_ROW)
            row:SetWidth(w)
            row.value = o[1]
            row.text:SetText(o[3] or o[2])
            S.FitText(row.text, w - 26, 12)
            row:Show()
        end
        for i = #list + 1, #rows do rows[i]:Hide(); rows[i].value = nil end
        content:SetHeight(math.max(1, #list * MENU_ROW))
        menu:SetSize(menuWidth, math.max(1, math.min(#list, maxRows)) * MENU_ROW + 2 * MENU_PAD)
        menu:ClearAllPoints()
        menu.home = nil
        -- un menu plus large que son bouton s'aligne sur son bord droit
        local side = menuWidth > width + 40 and "RIGHT" or "LEFT"
        if opts.up then menu:SetPoint("BOTTOM" .. side, b, "TOP" .. side, 0, 4)
        else menu:SetPoint("TOP" .. side, b, "BOTTOM" .. side, 0, -4) end
        sf.bar:SetValue(0)
        sf:SetVerticalScroll(0)
    end

    b:SetScript("OnClick", function()
        if not menu then build() end
        if menu:IsShown() and catcher:IsShown() then close() return end
        GameTooltip:Hide()
        fill()
        refreshRows()
        catcher:Show()
        menu:Show()
        chev:Flip(true)
        S.AnimateOpen(menu, 0, opts.up and -8 or 8)
    end)
    if opts.tooltip then
        b:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(opts.tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:HookScript("OnLeave", GameTooltip_Hide)
    end
    b:HookScript("OnHide", function() close(true) end)
    b.Refresh = refreshLabel
    refreshLabel()
    return b
end
