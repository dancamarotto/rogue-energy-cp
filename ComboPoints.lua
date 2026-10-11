local _, ns = ...

-- Combo points row above or below the energy bar. Each dot is a StatusBar
-- with range (i-1, i): fed the raw combo point count it fills itself, so
-- secret values in combat and instances are never read or compared.

local frame = ns.frame
local TEX = "Interface\\AddOns\\RogueEnergyCP\\Textures\\"
local MAX_DOTS = 10
local SAMPLE_POINTS = 3 -- shown in Edit Mode so the row can be judged

-- tintEmpty: the empty socket takes the user's color too (EditMode.lua
-- lists these styles in the Style dropdown)
ns.CP_STYLES = {
    { key = "classic", label = "Classic", tintEmpty = false },
    { key = "silver",  label = "Silver",  tintEmpty = false },
    { key = "square",  label = "Square",  tintEmpty = false },
    { key = "glow",    label = "Glow",    tintEmpty = true },
    { key = "flat",    label = "Flat",    tintEmpty = true },
    { key = "diamond", label = "Diamond", tintEmpty = true },
}
local STYLE_BY_KEY = {}
for _, style in ipairs(ns.CP_STYLES) do STYLE_BY_KEY[style.key] = style end

local row = CreateFrame("Frame", nil, frame)
local dots = {}
local dotCount = 0

-- With cpShowEmpty off the row fades out when the points drop to zero and
-- fades back in quickly with the first point.
local rowVisible = true
local rowFader = ns.NewFader(row)

local function SetRowVisible(visible)
    if visible == rowVisible then return end
    rowVisible = visible
    rowFader:Start(visible and 1 or 0, visible and ns.FADE_IN or ns.FADE_OUT)
end

local function GetDot(i)
    local dot = dots[i]
    if dot then return dot end
    dot = CreateFrame("Frame", nil, row)
    dot.empty = dot:CreateTexture(nil, "BACKGROUND")
    dot.empty:SetAllPoints()
    dot.bar = CreateFrame("StatusBar", nil, dot)
    dot.bar:SetAllPoints()
    dot.bar:SetMinMaxValues(i - 1, i) -- empty below i-1 points, full from i
    dot.bar:SetValue(0)
    dots[i] = dot
    return dot
end

local function GetPoints()
    if GetComboPoints then
        return GetComboPoints("player", "target")
    end
    return UnitPower("player", Enum.PowerType.ComboPoints)
end

-- true / false, or nil while the game keeps the count secret
local function HasPoints()
    local n
    pcall(function() n = GetPoints() + 0 end)
    if n == nil then return nil end
    return n > 0
end

local function MaxPoints()
    local n = 5
    pcall(function()
        local v = UnitPowerMax("player", Enum.PowerType.ComboPoints) + 0
        if v >= 1 and v <= MAX_DOTS then n = v end
    end)
    return n
end

function ns.UpdateComboPoints()
    local editing = ns.IsInEditMode()
    local points = editing and SAMPLE_POINTS or GetPoints()
    for i = 1, dotCount do
        dots[i].bar:SetValue(points)
    end
    SetRowVisible(editing or ns.db.cpShowEmpty or HasPoints() ~= false)
end

-- Re-reads every setting from ns.db. Called on login, when the max number
-- of points changes and whenever a setting changes in the Edit Mode dialog.
function ns.ApplyComboPoints()
    local db = ns.db
    local style = STYLE_BY_KEY[db.cpStyle] or STYLE_BY_KEY.classic
    local c = db.cpColor
    local count = MaxPoints()

    local x = 0
    for i = 1, MAX_DOTS do
        if i <= count then
            local dot = GetDot(i)
            dot:SetSize(db.cpSize, db.cpSize)
            dot:ClearAllPoints()
            dot:SetPoint("LEFT", row, "LEFT", x, 0)
            x = x + db.cpSize + db.cpGap
            dot.empty:SetTexture(TEX .. style.key .. "_empty")
            dot.bar:SetStatusBarTexture(TEX .. style.key .. "_full")
            dot.bar:SetStatusBarColor(c.r, c.g, c.b)
            if style.tintEmpty then
                dot.empty:SetVertexColor(c.r, c.g, c.b)
            else
                dot.empty:SetVertexColor(1, 1, 1)
            end
            dot:Show()
        elseif dots[i] then
            dots[i]:Hide()
        end
    end
    dotCount = count

    row:SetSize(count * db.cpSize + (count - 1) * db.cpGap, db.cpSize)
    row:ClearAllPoints()
    if db.cpSide == "BELOW" then
        row:SetPoint("TOP", frame, "BOTTOM", 0, -db.cpOffset)
    else
        row:SetPoint("BOTTOM", frame, "TOP", 0, db.cpOffset)
    end

    ns.UpdateComboPoints()
end

local events = CreateFrame("Frame", nil, frame)
events:SetScript("OnEvent", function(_, event, _, powerType)
    if event == "UNIT_MAXPOWER" then
        if powerType == "COMBO_POINTS" then ns.ApplyComboPoints() end
    elseif event == "UNIT_POWER_UPDATE" then
        if powerType == "COMBO_POINTS" then ns.UpdateComboPoints() end
    else -- PLAYER_TARGET_CHANGED, PLAYER_ENTERING_WORLD
        ns.UpdateComboPoints()
    end
end)

-- Safety net: some point changes (target swap, charges spent) may arrive
-- without an event on Forever, so refresh a few times a second while shown.
local THROTTLE = 0.1
local elapsedSinceUpdate = 0
events:SetScript("OnUpdate", function(_, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate < THROTTLE then return end
    elapsedSinceUpdate = 0
    ns.UpdateComboPoints()
end)

function ns.SetupComboPoints()
    events:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    events:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    ns.ApplyComboPoints()
end
