local ADDON, ns = ...

-- Saved settings. Everything is account wide; only the position is stored
-- per Edit Mode layout (see EditMode.lua).
ns.defaults = {
    layouts = {},  -- [layoutName] = { point = "CENTER", x = 0, y = 0 }
    width = 220,
    height = 18,
}

local frame = CreateFrame("Frame", "RogueEnergyCP", UIParent)
ns.frame = frame
frame:SetSize(ns.defaults.width, ns.defaults.height)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:Hide()

-- Placeholder look until the energy bar exists, so the frame can be
-- placed in Edit Mode.
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.6)

local function CopyDefaults(src, dst)
    for key, value in pairs(src) do
        if type(value) == "table" then
            if type(dst[key]) ~= "table" then dst[key] = {} end
            CopyDefaults(value, dst[key])
        elseif dst[key] == nil then
            dst[key] = value
        end
    end
end

local function IsRogue()
    local _, class = UnitClass("player")
    return class == "ROGUE"
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON then return end
        RogueEnergyCPDB = RogueEnergyCPDB or {}
        CopyDefaults(ns.defaults, RogueEnergyCPDB)
        ns.db = RogueEnergyCPDB
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if not IsRogue() then return end
        ns.SetupEditMode()
    end
end)

SLASH_ROGUEENERGYCP1 = "/recp"
SlashCmdList.ROGUEENERGYCP = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "reset" then
        ns.SavePosition("CENTER", 0, 0)
        ns.ApplyPosition()
    elseif InCombatLockdown() then
        print("|cff00ff00Rogue Energy CP:|r Edit Mode cannot be opened in combat.")
    else
        ShowUIPanel(EditModeManagerFrame)
    end
end
