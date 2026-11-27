-- iMorph Rack (Forever) : envoi des commandes à iMorph et détection de l'injection
local _, ns = ...

-- Mots-clés refusés : tout ce qui touche au gameplay (drapeaux, collisions, vitesse, etc.)
ns.BLOCKED = { "flag", "speed", "fly", "tele", "nameplate", "collision", "wallclimb", "gravity" }

function ns.IsAllowed(cmd)
    local l = cmd:lower()
    for _, word in ipairs(ns.BLOCKED) do
        if l:find(word, 1, true) then return false, word end
    end
    return true
end

-- Détection de l'injection d'iMorph.exe : à l'injection il écrit "iMorph: x.y.z loaded." dans le chat.
-- L'injection dure jusqu'à la fermeture du jeu : on retient l'heure de démarrage du processus
-- (time() - debugprofilestop()), identique après un /reload ou un changement de perso, différente au relancement.
local function ProcessStart()
    return time() - math.floor(debugprofilestop() / 1000)
end

function ns.IsInjected()
    local s = ns.db and ns.db.injectedProcess
    return s ~= nil and math.abs(s - ProcessStart()) <= 5
end

local function WatchChat(_, text)
    -- certains messages (combat, instances) sont des "valeurs secrètes" illisibles pour les addons
    if issecretvalue and issecretvalue(text) then return end
    if ns.db and type(text) == "string" and text:find("iMorph") and text:find("loaded") then
        local wasInjected = ns.IsInjected()
        ns.db.injectedProcess = ProcessStart()
        -- injection neuve : aucun morph actif, le genre affiché est le vrai
        if not wasInjected and ns.ClearGender then ns.ClearGender() end
        -- iMorph vient d'être injecté : on applique ce qui attendait (réapplication auto)
        if not wasInjected and ns.OnInjected then C_Timer.After(1, ns.OnInjected) end
    end
end
for i = 1, NUM_CHAT_WINDOWS or 10 do
    local cf = _G["ChatFrame" .. i]
    if cf then hooksecurefunc(cf, "AddMessage", WatchChat) end
end

local function SendOne(cmd)
    cmd = strtrim(cmd)
    if cmd == "" then return end
    local ok, word = ns.IsAllowed(cmd)
    if not ok then
        print("|cffff5555iMorph Rack|r : " .. ns.L["Command refused"] .. " (" .. word .. ") : " .. cmd)
        return
    end
    -- ".gender" d'iMorph n'a pas d'argument : il bascule. On garde ".gender 0/1" (valeur absolue)
    -- et on n'envoie la bascule que si le genre affiché n'est pas déjà le bon.
    -- ".skin" (presets de la 1.2.0) n'existe pas dans iMorph : c'est ".skincolor"
    cmd = cmd:gsub("^%.[Ss][Kk][Ii][Nn](%s)", ".skincolor%1")
    local track = cmd
    local g = cmd:lower():match("^%.gender%s*(%d?)$")
    if g then
        local now = ns.CurrentGender()
        local want = g ~= "" and math.min(tonumber(g), 1) or 1 - now
        track = ".gender " .. want
        if want == now then
            if ns.Track then ns.Track(track) end
            return
        end
        cmd = ".gender"
        ns.SetGender(want)
    end
    -- l'addon "iMorph" expose son gestionnaire : on l'appelle directement, sans passer par la barre de chat
    if iMorphChatHandler then
        iMorphChatHandler(cmd)
    else
        local eb = DEFAULT_CHAT_FRAME.editBox or ChatFrame1EditBox
        eb:SetText(cmd)
        ChatEdit_SendText(eb, 0)
        eb:SetText("")
        if ChatEdit_DeactivateChat then ChatEdit_DeactivateChat(eb) end
    end
    if ns.Track then ns.Track(track) end
end

-- Exécute une ou plusieurs commandes séparées par ";" ou retour à la ligne
function ns.Run(text)
    -- ".item 16 1 .item 17 2" sans ; : on coupe aussi avant chaque nouvelle commande
    text = text:gsub("\n", ";"):gsub("%s+(%.%a)", ";%1")
    for part in (text .. ";"):gmatch("([^;]*);") do
        SendOne(part)
    end
end
