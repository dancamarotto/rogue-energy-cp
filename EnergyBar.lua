local _, ns = ...

-- Energy bar filling ns.frame. Energy and max energy can be secret values
-- (combat, instances): they are fed raw into the StatusBar and FontString,
-- never read, compared or used in arithmetic. The color comes from the game
-- through a step color curve evaluated by UnitPowerPercent.

local LSM = LibStub("LibSharedMedia-3.0")
local frame = ns.frame
local POWER = Enum.PowerType.Energy
local TEXT_INSET = 4

local border = frame:CreateTexture(nil, "BACKGROUND")
border:SetAllPoints()
border:SetColorTexture(0, 0, 0, 0.8)

local bar = CreateFrame("StatusBar", nil, frame)
bar:SetPoint("TOPLEFT", 1, -1)
bar:SetPoint("BOTTOMRIGHT", -1, 1)
bar:SetMinMaxValues(0, 100)
bar:SetValue(0)

local bg = bar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetVertexColor(0.15, 0.15, 0.15, 0.9)

local text = bar:CreateFontString(nil, "OVERLAY")

local colorCurve = C_CurveUtil.CreateColorCurve()
colorCurve:SetType(Enum.LuaCurveType.Step)

local function ToColor(c)
    return CreateColor(c.r, c.g, c.b, 1)
end

local function RebuildColorCurve()
    local db = ns.db
    colorCurve:ClearPoints()
    colorCurve:AddPoint(0, ToColor(db.normalColor))
    colorCurve:AddPoint(db.cappedThreshold, ToColor(db.cappedColor))
end

local function UpdateMax()
    bar:SetMinMaxValues(0, UnitPowerMax("player", POWER))
end

function ns.UpdateEnergyBar()
    local power = UnitPower("player", POWER)
    bar:SetValue(power)
    text:SetText(power)
    local color = UnitPowerPercent("player", POWER, false, colorCurve)
    if color then
        bar:SetStatusBarColor(color:GetRGBA())
    end
end

-- Re-reads every setting from ns.db. Called on login and whenever a setting
-- changes in the Edit Mode dialog.
function ns.ApplyEnergyBar()
    local db = ns.db
    frame:SetSize(db.width, db.height)

    local texture = LSM:Fetch("statusbar", db.texture)
    bar:SetStatusBarTexture(texture)
    bg:SetTexture(texture)

    text:SetFont(LSM:Fetch("font", db.font), db.fontSize, "OUTLINE")
    text:ClearAllPoints()
    if db.textAlign == "LEFT" then
        text:SetPoint("LEFT", bar, "LEFT", TEXT_INSET, 0)
        text:SetJustifyH("LEFT")
    elseif db.textAlign == "RIGHT" then
        text:SetPoint("RIGHT", bar, "RIGHT", -TEXT_INSET, 0)
        text:SetJustifyH("RIGHT")
    else
        text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        text:SetJustifyH("CENTER")
    end
    text:SetShown(db.showText)

    RebuildColorCurve()
    UpdateMax()
    ns.UpdateEnergyBar()
end

local events = CreateFrame("Frame", nil, frame)
events:SetScript("OnEvent", function(_, event, _, powerType)
    if event == "UNIT_MAXPOWER" or event == "PLAYER_ENTERING_WORLD" then
        UpdateMax()
    elseif powerType ~= "ENERGY" then
        return
    end
    ns.UpdateEnergyBar()
    -- out of combat the visibility follows the energy (fade once full)
    if not UnitAffectingCombat("player") then
        ns.UpdateVisibility()
    end
end)

function ns.SetupEnergyBar()
    events:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    events:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    events:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    ns.ApplyEnergyBar()
end
