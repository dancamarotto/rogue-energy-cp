local ADDON, ns = ...

-- Saved settings. Everything is account wide; only the position is stored
-- per Edit Mode layout (see EditMode.lua).
ns.defaults = {
    layouts = {},  -- [layoutName] = { point = "CENTER", x = 0, y = 0 }

    -- bar
    width = 220,
    height = 18,
    texture = "Blizzard",
    normalColor = { r = 1.0, g = 0.82, b = 0.10 },
    cappedColor = { r = 1.0, g = 0.30, b = 0.20 },
    cappedThreshold = 0.9, -- fraction of max energy from which cappedColor is used

    -- text
    showText = true,
    textAlign = "CENTER", -- LEFT | CENTER | RIGHT
    font = "Friz Quadrata TT",
    fontSize = 14,

    -- combo points
    cpSide = "ABOVE", -- ABOVE | BELOW the bar
    cpOffset = 2,     -- distance from the bar
    cpStyle = "classic",
    cpSize = 14,
    cpGap = 2,
    cpColor = { r = 0.92, g = 0.13, b = 0.16 },
    cpShowEmpty = true, -- false hides the row while there are no points

    -- visibility
    outOfCombatAlpha = 0, -- 0 hides the frame out of combat
    showInStealth = true,
}

local frame = CreateFrame("Frame", "RogueEnergyCP", UIParent)
ns.frame = frame
frame:SetSize(ns.defaults.width, ns.defaults.height)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:Hide()

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

-- Visibility: full alpha in combat, in stealth and in Edit Mode. Out of
-- combat the frame stays visible while energy is below the cap and fades to
-- outOfCombatAlpha once energy is full (not configurable). Out of combat the
-- energy can still be secret (instances): then the fade is skipped and the
-- game picks the alpha itself through a step curve evaluated by
-- UnitPowerPercent, exactly like the bar color.
local POWER = Enum.PowerType.Energy
local FADE_DURATION = 1
local state -- "shown" | "fading" | "faded" | "secret"
local fadeTo, fadeElapsed

local alphaCurve = C_CurveUtil.CreateCurve()
alphaCurve:SetType(Enum.LuaCurveType.Step)

local function RebuildAlphaCurve()
    alphaCurve:ClearPoints()
    alphaCurve:AddPoint(0, 1)
    alphaCurve:AddPoint(1, ns.db.outOfCombatAlpha)
end

-- Errors when the values are secret; always called through pcall.
local function IsEnergyFull()
    return UnitPower("player", POWER) >= UnitPowerMax("player", POWER)
end

local function StopFade()
    frame:SetScript("OnUpdate", nil)
end

local function SetShown()
    StopFade()
    state = "shown"
    frame:SetAlpha(1)
    frame:Show()
end

local function SetFaded(alpha)
    StopFade()
    state = "faded"
    frame:SetAlpha(alpha)
    frame:SetShown(alpha > 0)
end

local function OnFadeUpdate(self, elapsed)
    fadeElapsed = fadeElapsed + elapsed
    local progress = fadeElapsed / FADE_DURATION
    if progress >= 1 then
        SetFaded(fadeTo)
    else
        self:SetAlpha(1 + (fadeTo - 1) * progress)
    end
end

local function StartFade(target)
    state, fadeTo, fadeElapsed = "fading", target, 0
    frame:SetScript("OnUpdate", OnFadeUpdate)
end

-- Called on every visibility event and on every energy update out of combat.
function ns.UpdateVisibility()
    local db = ns.db
    if not db then return end

    if ns.IsInEditMode()
        or UnitAffectingCombat("player")
        or (db.showInStealth and IsStealthed())
    then
        SetShown()
        return
    end

    local ok, full = pcall(IsEnergyFull)
    if not ok then
        -- secret energy: alpha 1 below the cap, outOfCombatAlpha at the cap
        StopFade()
        state = "secret"
        frame:Show()
        if not pcall(frame.SetAlpha, frame, UnitPowerPercent("player", POWER, false, alphaCurve)) then
            frame:SetAlpha(1)
        end
    elseif not full then
        SetShown()
    elseif state == "shown" then
        StartFade(db.outOfCombatAlpha)
    elseif state ~= "fading" then
        SetFaded(db.outOfCombatAlpha) -- already faded, coming from secret, or login
    end
end

-- Re-reads the visibility settings from ns.db (login and Edit Mode dialog).
function ns.ApplyVisibility()
    RebuildAlphaCurve()
    state = nil
    ns.UpdateVisibility()
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
        ns.SetupEnergyBar()
        ns.SetupComboPoints()
        ns.SetupEditMode()
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("UPDATE_STEALTH")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        ns.ApplyVisibility()
    else
        ns.UpdateVisibility()
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
