-- iMorph Rack (Forever) : bouton de la minimap
local ADDON, ns = ...
local L = ns.L

local function UpdatePosition(btn)
    local a = math.rad(ns.db.minimapAngle or 200)
    btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    local btn = CreateFrame("Button", "iMorphRackMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(ns.ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    btn:RegisterForClicks("LeftButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnClick", function() ns.Toggle() end)
    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local s = Minimap:GetEffectiveScale()
            ns.db.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
            self:ClearAllPoints()
            UpdatePosition(self)
        end)
    end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("iMorph Rack")
        GameTooltip:AddLine(L["Click: open / close"], 1, 1, 1)
        GameTooltip:AddLine(L["Drag: move"], 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    UpdatePosition(btn)
end)
