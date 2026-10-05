-- iMorph Rack (Forever) : localisation (anglais / français, choisie dans la fenêtre ; "auto" = langue du client)
local _, ns = ...

-- Les chaînes anglaises servent de clés ; traduction française ci-dessous
local FR = {}
ns.FR = FR
ns.IS_FRENCH = GetLocale() == "frFR"
ns.L = setmetatable({}, { __index = function(_, k) return ns.IS_FRENCH and FR[k] or k end })

-- "auto" = langue du client
function ns.ApplyLanguage(lang)
    if lang == "enUS" then ns.IS_FRENCH = false
    elseif lang == "frFR" then ns.IS_FRENCH = true
    else ns.IS_FRENCH = GetLocale() == "frFR" end
end
