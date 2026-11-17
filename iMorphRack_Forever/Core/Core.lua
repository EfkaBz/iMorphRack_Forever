-- iMorph Rack (Forever) : sauvegarde et commande /imr
local ADDON, ns = ...

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON then return end
    iMorphRackDB = iMorphRackDB or {}
    iMorphRackDB.custom = iMorphRackDB.custom or {}
    iMorphRackDB.presets = iMorphRackDB.presets or {}
    iMorphRackDB.chars = iMorphRackDB.chars or {}
    ns.db = iMorphRackDB
    ns.ApplyLanguage(ns.db.lang)
    ns.Skin.ApplyTheme(ns.db.theme or "default")
    f:UnregisterEvent("ADDON_LOADED")
end)

-- /imr : ouvre / ferme   ·   /imr <preset> : applique un preset   ·   /imr reset   ·   /imr bug
SLASH_IMORPHRACK1 = "/imr"
SLASH_IMORPHRACK2 = "/imorphrack"
SlashCmdList.IMORPHRACK = function(msg)
    msg = strtrim(msg or "")
    if msg == "" then ns.Toggle() return end
    if msg:lower() == "reset" then ns.Run(".reset") return end
    if msg:lower() == "bug" then ns.ReportBug() return end
    local p = ns.FindPreset(msg)
    if p then
        ns.ApplyPreset(p)
    else
        print("|cff4fd2ffiMorph Rack|r : " .. format(ns.L["No preset named \"%s\"."], msg))
    end
end
