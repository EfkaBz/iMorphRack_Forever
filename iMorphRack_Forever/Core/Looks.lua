-- iMorph Rack (Forever) : suivi du look actuel, presets et réapplication à la connexion
local _, ns = ...
local L = ns.L

-- commandes suivies, dans l'ordre où on les renvoie (l'itemset avant les objets pour qu'ils priment)
local ORDER = { "race", "gender", "morph", "scale", "skin", "face", "hair", "haircolor", "features",
    "itemset", "item", "enchant", "title", "mount", "morphpet", "shapeshift" }
local TRACKED, KEYED = {}, { item = true, enchant = true, shapeshift = true }
for _, k in ipairs(ORDER) do TRACKED[k] = true end

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
    return c
end

-- appelé pour chaque commande envoyée : met à jour le look actuel
function ns.Track(cmd)
    if not ns.db then return end
    local name, args = cmd:match("^%.(%a+)%s*(.-)%s*$")
    if not name then return end
    name = name:lower()
    local look = ns.CharDB().look
    if name == "reset" then
        wipe(look)
    elseif KEYED[name] then
        local k, v = args:match("^(%S+)%s+(.+)$")
        if not k then return end
        look[name] = look[name] or {}
        look[name][k] = v
    elseif name == "mount" and args == "0" then
        look.mount = nil
    elseif TRACKED[name] and args ~= "" then
        look[name] = args
    end
    if ns.OnLookChanged then ns.OnLookChanged() end
end

-- look -> liste de commandes
function ns.LookCommands(look)
    local out = {}
    for _, k in ipairs(ORDER) do
        local v = look[k]
        if type(v) == "table" then
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

-- un preset remplace tout le look : on repart de zéro
function ns.ApplyPreset(p)
    ns.Run(".reset; " .. p.cmd)
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
            ns.Run(cmds)
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
        pending = c.auto ~= nil and c.auto ~= "off"
        -- laisse le temps au personnage d'apparaître avant de le modifier
        C_Timer.After(3, AutoApply)
    end
end)
