-- iMorph Rack (Forever) : sauvegarde et commande /imr
local ADDON, ns = ...

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON then return end
    iMorphRackDB = iMorphRackDB or {}
    iMorphRackDB.custom = iMorphRackDB.custom or {}
    ns.db = iMorphRackDB
    ns.ApplyLanguage(ns.db.lang)
    f:UnregisterEvent("ADDON_LOADED")
end)

SLASH_IMORPHRACK1 = "/imr"
SLASH_IMORPHRACK2 = "/imorphrack"
SlashCmdList.IMORPHRACK = function() ns.Toggle() end
