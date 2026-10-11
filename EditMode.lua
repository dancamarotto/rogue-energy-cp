local _, ns = ...

local LEM = LibStub("LibEditMode")
local LSM = LibStub("LibSharedMedia-3.0")
local frame = ns.frame
local inEditMode

function ns.GetPosition()
    local layoutName = LEM:GetActiveLayoutName()
    return (layoutName and ns.db.layouts[layoutName]) or { point = "CENTER", x = 0, y = 0 }
end

function ns.ApplyPosition()
    local pos = ns.GetPosition()
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
end

function ns.SavePosition(point, x, y)
    local layoutName = LEM:GetActiveLayoutName()
    if not layoutName then return end
    local pos = ns.db.layouts[layoutName]
    if not pos then
        pos = {}
        ns.db.layouts[layoutName] = pos
    end
    pos.point, pos.x, pos.y = point, x, y
end

function ns.IsInEditMode()
    return inEditMode
end

-- Settings dialog. Every setting is account wide (ns.db[key]); get/set
-- ignore the layout name. The percent sliders convert between the 0-1
-- value stored and the 0-100 shown.
local T = LEM.SettingType

local function Slider(name, key, minValue, maxValue, apply, desc)
    return {
        kind = T.Slider, name = name, desc = desc,
        default = ns.defaults[key], minValue = minValue, maxValue = maxValue, valueStep = 1,
        get = function() return ns.db[key] end,
        set = function(_, value) ns.db[key] = value; apply() end,
    }
end

local function PercentSlider(name, key, minValue, maxValue, apply, desc)
    return {
        kind = T.Slider, name = name, desc = desc,
        default = ns.defaults[key] * 100, minValue = minValue, maxValue = maxValue, valueStep = 1,
        formatter = function(value) return value .. "%" end,
        get = function() return math.floor(ns.db[key] * 100 + 0.5) end,
        set = function(_, value) ns.db[key] = value / 100; apply() end,
    }
end

local function Checkbox(name, key, apply, desc)
    return {
        kind = T.Checkbox, name = name, desc = desc, default = ns.defaults[key],
        get = function() return ns.db[key] end,
        set = function(_, value) ns.db[key] = value; apply() end,
    }
end

local function Dropdown(name, key, values, apply, height)
    return {
        kind = T.Dropdown, name = name, default = ns.defaults[key], values = values, height = height,
        get = function() return ns.db[key] end,
        set = function(_, value) ns.db[key] = value; apply() end,
    }
end

local function ColorPicker(name, key, apply)
    local d = ns.defaults[key]
    return {
        kind = T.ColorPicker, name = name, default = CreateColor(d.r, d.g, d.b, 1),
        get = function()
            local c = ns.db[key]
            return CreateColor(c.r, c.g, c.b, 1)
        end,
        set = function(_, color)
            local c = ns.db[key]
            c.r, c.g, c.b = color:GetRGB()
            apply()
        end,
    }
end

local function Divider(name)
    return { kind = T.Divider, name = name }
end

local function MediaValues(mediaType)
    return function()
        local values = {}
        for _, name in ipairs(LSM:List(mediaType)) do
            values[#values + 1] = { text = name, value = name }
        end
        return values
    end
end

local function BuildSettings()
    local bar, cp, vis = ns.ApplyEnergyBar, ns.ApplyComboPoints, ns.ApplyVisibility

    local styles = {}
    for _, style in ipairs(ns.CP_STYLES) do
        styles[#styles + 1] = { text = style.label, value = style.key }
    end

    return {
        Slider("Width", "width", 80, 600, bar),
        Slider("Height", "height", 8, 60, bar),
        Dropdown("Texture", "texture", MediaValues("statusbar"), bar, 400),
        ColorPicker("Normal color", "normalColor", bar),
        ColorPicker("Capped color", "cappedColor", bar),
        PercentSlider("Capped at", "cappedThreshold", 50, 100, bar,
            "Energy from which the bar uses the capped color."),

        Divider("Text"),
        Checkbox("Show text", "showText", bar),
        Dropdown("Align", "textAlign", {
            { text = "Left", value = "LEFT" },
            { text = "Center", value = "CENTER" },
            { text = "Right", value = "RIGHT" },
        }, bar),
        Dropdown("Font", "font", MediaValues("font"), bar, 400),
        Slider("Size", "fontSize", 8, 32, bar),

        Divider("Combo points"),
        Dropdown("Side", "cpSide", {
            { text = "Above the bar", value = "ABOVE" },
            { text = "Below the bar", value = "BELOW" },
        }, cp),
        Dropdown("Style", "cpStyle", styles, cp),
        ColorPicker("Color", "cpColor", cp),
        Slider("Size", "cpSize", 8, 30, cp),
        Slider("Gap", "cpGap", 0, 10, cp),
        Slider("Distance", "cpOffset", 0, 20, cp, "Space between the bar and the combo points."),
        Checkbox("Show empty", "cpShowEmpty", cp,
            "Keep the empty sockets visible when there are no combo points."),

        Divider("Visibility"),
        PercentSlider("Out of combat alpha", "outOfCombatAlpha", 0, 100, vis,
            "Alpha of the bar out of combat once energy is full (0 hides it). "
            .. "It stays fully visible while energy is below the cap, in combat and in Edit Mode."),
        Checkbox("Show in stealth", "showInStealth", vis),
    }
end

function ns.SetupEditMode()
    ns.ApplyPosition()

    -- callbacks first: AddFrame may fire "layout" right away
    LEM:RegisterCallback("enter", function()
        inEditMode = true
        ns.UpdateEnergyBar()
        ns.UpdateComboPoints() -- sample points while editing
        ns.UpdateVisibility()
    end)
    LEM:RegisterCallback("exit", function()
        inEditMode = nil
        ns.UpdateComboPoints()
        ns.UpdateVisibility()
    end)
    LEM:RegisterCallback("layout", function()
        ns.ApplyPosition()
    end)
    LEM:RegisterCallback("create", function(layoutName, _, sourceLayoutName)
        local layouts = ns.db.layouts
        local source = sourceLayoutName and layouts[sourceLayoutName]
        if source and not layouts[layoutName] then
            layouts[layoutName] = CopyTable(source)
        end
        ns.ApplyPosition() -- the game may already have switched to it
    end)
    LEM:RegisterCallback("rename", function(oldName, newName)
        local layouts = ns.db.layouts
        if layouts[oldName] and not layouts[newName] then
            layouts[newName] = layouts[oldName]
        end
        layouts[oldName] = nil
    end)
    LEM:RegisterCallback("delete", function(layoutName)
        ns.db.layouts[layoutName] = nil
    end)

    -- Empty system name: the Edit Mode label would sit over the bar and hide
    -- the energy text, which is what the font settings are meant to preview.
    LEM:AddFrame(frame, function(_, _, point, x, y)
        ns.SavePosition(point, x, y)
    end, { point = "CENTER", x = 0, y = 0 }, "")
    LEM:AddFrameSettings(frame, BuildSettings())
end
