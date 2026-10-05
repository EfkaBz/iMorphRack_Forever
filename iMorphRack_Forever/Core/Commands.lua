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
        ns.db.injectedProcess = ProcessStart()
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
    -- l'addon "iMorph" expose son gestionnaire : on l'appelle directement, sans passer par la barre de chat
    if iMorphChatHandler then
        iMorphChatHandler(cmd)
        return
    end
    local eb = DEFAULT_CHAT_FRAME.editBox or ChatFrame1EditBox
    eb:SetText(cmd)
    ChatEdit_SendText(eb, 0)
    eb:SetText("")
    if ChatEdit_DeactivateChat then ChatEdit_DeactivateChat(eb) end
end

-- Exécute une ou plusieurs commandes séparées par ";" ou retour à la ligne
function ns.Run(text)
    -- ".item 16 1 .item 17 2" sans ; : on coupe aussi avant chaque nouvelle commande
    text = text:gsub("\n", ";"):gsub("%s+(%.%a)", ";%1")
    for part in (text .. ";"):gmatch("([^;]*);") do
        SendOne(part)
    end
end
