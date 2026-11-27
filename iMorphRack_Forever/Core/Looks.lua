-- iMorph Rack (Forever) : suivi du look actuel, presets et réapplication à la connexion
local _, ns = ...
local L = ns.L

-- commandes suivies, dans l'ordre où on les renvoie (l'itemset avant les objets pour qu'ils priment)
-- "cust" = options de personnalisation (.facialhair 2, .skincolor 3...), renvoyées telles quelles
local ORDER = { "race", "gender", "morph", "scale", "face", "hair", "haircolor", "features", "cust",
    "itemset", "item", "enchant", "title", "mount", "morphpet", "shapeshift" }
local TRACKED, KEYED = {}, { item = true, enchant = true, shapeshift = true }
for _, k in ipairs(ORDER) do TRACKED[k] = true end
TRACKED.cust = nil
-- modèle de base : envoyé d'abord, le reste un peu après (iMorph reconstruit le modèle)
local BASE = { race = true, gender = true, morph = true }

-- options de personnalisation reconnues par iMorph (liste de l'addon iMorph si présent)
local FALLBACK_CUST = { "skincolor", "face", "hair", "hairstyle", "haircolor", "facialhair", "features", "beard",
    "mustache", "sideburns", "eyecolor", "eyebrows", "earrings", "piercings", "tattoo", "horns", "tusks", "markings" }
function ns.CustomizationNames()
    local list = type(iMorphCustomization) == "function" and iMorphCustomization() or FALLBACK_CUST
    local out = {}
    for _, n in ipairs(list) do
        if n == strtrim(n) then out[#out + 1] = n end
    end
    return out
end
local custSet
local function IsCustomization(name)
    if not custSet then
        custSet = {}
        for _, n in ipairs(ns.CustomizationNames()) do custSet[n] = true end
    end
    return custSet[name]
end

-- réglages du personnage (look actuel, réapplication auto)
function ns.CharDB()
    local key = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    ns.db.chars = ns.db.chars or {}
    local c = ns.db.chars[key]
    if not c then
        c = { look = {}, auto = "off" }
        ns.db.chars[key] = c
    end
    c.look = c.look or {}
    -- 1.2.0 enregistrait ".skin", qui n'existe pas dans iMorph : c'est ".skincolor"
    if c.look.skin then
        c.look.cust = c.look.cust or {}
        c.look.cust.skincolor = c.look.cust.skincolor or c.look.skin
        c.look.skin = nil
    end
    return c
end

-- genre affiché : iMorph ne sait que basculer, on retient donc l'état (nil = genre réel)
function ns.CurrentGender()
    local g = ns.db and ns.CharDB().gender
    if g then return g end
    return UnitSex("player") == 3 and 1 or 0
end
function ns.SetGender(g) if ns.db then ns.CharDB().gender = g end end
function ns.ClearGender() if ns.db then ns.CharDB().gender = nil end end

-- appelé pour chaque commande envoyée : met à jour le look actuel
function ns.Track(cmd)
    if not ns.db then return end
    local name, args = cmd:match("^%.(%a+)%s*(.-)%s*$")
    if not name then return end
    name = name:lower()
    local look = ns.CharDB().look
    if name == "reset" then
        wipe(look)
        ns.ClearGender()
    elseif KEYED[name] then
        local k, v = args:match("^(%S+)%s+(.+)$")
        if not k then return end
        look[name] = look[name] or {}
        look[name][k] = v
    elseif name == "mount" and args == "0" then
        look.mount = nil
    elseif TRACKED[name] and args ~= "" then
        look[name] = args
    elseif IsCustomization(name) and args ~= "" then
        look.cust = look.cust or {}
        look.cust[name] = args
    end
    if ns.OnLookChanged then ns.OnLookChanged() end
end

-- look -> liste de commandes
function ns.LookCommands(look)
    local out = {}
    for _, k in ipairs(ORDER) do
        local v = look[k]
        if k == "cust" and type(v) == "table" then
            local keys = {}
            for kk in pairs(v) do keys[#keys + 1] = kk end
            table.sort(keys)
            for _, kk in ipairs(keys) do out[#out + 1] = "." .. kk .. " " .. v[kk] end
        elseif type(v) == "table" then
            local keys = {}
            for kk in pairs(v) do keys[#keys + 1] = kk end
            table.sort(keys, function(a, b) return (tonumber(a) or 0) < (tonumber(b) or 0) end)
            for _, kk in ipairs(keys) do out[#out + 1] = "." .. k .. " " .. kk .. " " .. v[kk] end
        elseif v then
            out[#out + 1] = "." .. k .. " " .. v
        end
    end
    return table.concat(out, "; "), #out
end

-- nombre de commandes d'une chaîne "a; b; c"
function ns.CountCommands(text)
    local n = 0
    for part in (text .. ";"):gmatch("([^;]*);") do
        if strtrim(part) ~= "" then n = n + 1 end
    end
    return n
end

-- Presets -------------------------------------------------------------------------
function ns.FindPreset(name)
    local low = name:lower()
    for i, p in ipairs(ns.db.presets) do
        if p.name:lower() == low then return p, i end
    end
end

-- Applique un look complet en trois temps : .reset, puis le modèle de base (race, genre, morph),
-- puis le reste. Tout envoyer d'un coup faisait perdre des commandes pendant qu'iMorph
-- reconstruisait le modèle : le preset gardait alors l'apparence du précédent.
local applyGen = 0
function ns.ApplyLook(text)
    local base, rest = {}, {}
    for part in (text:gsub("\n", ";") .. ";"):gmatch("([^;]*);") do
        part = strtrim(part)
        local name = part:match("^%.(%a+)")
        if name and name:lower() ~= "reset" then
            if BASE[name:lower()] then base[#base + 1] = part else rest[#rest + 1] = part end
        end
    end
    applyGen = applyGen + 1
    local gen = applyGen
    local function later(delay, list)
        if #list == 0 then return end
        C_Timer.After(delay, function()
            if gen == applyGen then ns.Run(table.concat(list, "; ")) end
        end)
    end
    ns.Run(".reset")
    later(0.4, base)
    later(#base > 0 and 1.0 or 0.4, rest)
end

-- un preset remplace tout le look : on repart de zéro
function ns.ApplyPreset(p)
    ns.ApplyLook(p.cmd)
    print("|cff4fd2ffiMorph Rack|r : " .. format(L["Preset \"%s\" applied."], p.name))
end

function ns.SavePreset(name, cmd)
    local p = ns.FindPreset(name)
    if p then p.cmd = cmd
    else table.insert(ns.db.presets, { name = name, cmd = cmd }) end
end

-- Réapplication à la connexion -----------------------------------------------------
local pending = false

local function AutoApply()
    if not pending or not ns.db then return end
    if not ns.IsInjected() then return end -- on attend l'injection (ns.OnInjected)
    pending = false
    local c = ns.CharDB()
    if c.auto == "last" then
        local cmds, n = ns.LookCommands(c.look)
        if n > 0 then
            ns.ApplyLook(cmds)
            print("|cff4fd2ffiMorph Rack|r : " .. L["Last look reapplied."])
        end
    elseif c.auto and c.auto ~= "off" then
        local p = ns.FindPreset(c.auto)
        if p then ns.ApplyPreset(p) end
    end
end
ns.OnInjected = AutoApply

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, _, isLogin, isReload)
    if isLogin or isReload then
        local c = ns.CharDB()
        -- nouvelle connexion : iMorph a remis le personnage à zéro
        if isLogin then c.gender = nil end
        pending = c.auto ~= nil and c.auto ~= "off"
        -- laisse le temps au personnage d'apparaître avant de le modifier
        C_Timer.After(3, AutoApply)
    end
end)
