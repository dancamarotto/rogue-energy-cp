local _, ns = ...

-- Options > AddOns page, built with the game's Settings API so it looks
-- like the native pages: appearance (texture, colors, font) and visibility.
-- Size, text layout and the combo points arrangement stay in Edit Mode.
-- Every setting is a proxy over ns.db[key]; the setter calls the module's
-- Apply() so the change is live.

local LSM = LibStub("LibSharedMedia-3.0")
local PREFIX = "ROGUE_ENERGY_CP_"
local category, layout

-- Colors travel through the Settings API as "rrggbb" strings.
local function ToHex(r, g, b)
    return string.format("%02x%02x%02x",
        math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function FromHex(hex)
    return tonumber(hex:sub(1, 2), 16) / 255,
        tonumber(hex:sub(3, 4), 16) / 255,
        tonumber(hex:sub(5, 6), 16) / 255
end

local function Proxy(key, varType, name, default, get, set)
    return Settings.RegisterProxySetting(category, PREFIX .. key, varType, name, default, get, set)
end

local function Header(name)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(name))
end

local function Checkbox(name, key, apply, tooltip)
    local setting = Proxy(key, Settings.VarType.Boolean, name, ns.defaults[key],
        function() return ns.db[key] end,
        function(value) ns.db[key] = value; apply() end)
    Settings.CreateCheckbox(category, setting, tooltip)
end

-- Stores 0-1, shows 0-100 %.
local function PercentSlider(name, key, minValue, maxValue, apply, tooltip)
    local function ToPercent(fraction) return math.floor(fraction * 100 + 0.5) end
    local setting = Proxy(key, Settings.VarType.Number, name, ToPercent(ns.defaults[key]),
        function() return ToPercent(ns.db[key]) end,
        function(value) ns.db[key] = value / 100; apply() end)
    local options = Settings.CreateSliderOptions(minValue, maxValue, 1)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return value .. "%"
    end)
    Settings.CreateSlider(category, setting, options, tooltip)
end

local function MediaDropdown(name, key, mediaType, apply, tooltip)
    local setting = Proxy(key, Settings.VarType.String, name, ns.defaults[key],
        function() return ns.db[key] end,
        function(value) ns.db[key] = value; apply() end)
    Settings.CreateDropdown(category, setting, function()
        local container = Settings.CreateControlTextContainer()
        for _, media in ipairs(LSM:List(mediaType)) do
            container:Add(media, media)
        end
        return container:GetData()
    end, tooltip)
end

local function ColorPicker(name, key, apply, tooltip)
    local d = ns.defaults[key]
    local setting = Proxy(key, Settings.VarType.String, name, ToHex(d.r, d.g, d.b),
        function()
            local c = ns.db[key]
            return ToHex(c.r, c.g, c.b)
        end,
        function(value)
            local c = ns.db[key]
            c.r, c.g, c.b = FromHex(value)
            apply()
        end)
    layout:AddInitializer(Settings.CreateControlInitializer("RogueEnergyCPColorControlTemplate", setting, nil, tooltip))
end

-- Color control for the settings list (Options.xml): the native list has
-- no color picker, so this is a swatch in the control column that opens
-- the game's ColorPickerFrame. Follows the setting like the native controls
-- do, so the Defaults button updates it too.
RogueEnergyCPColorControlMixin = CreateFromMixins(SettingsControlMixin)

function RogueEnergyCPColorControlMixin:Init(initializer)
    SettingsControlMixin.Init(self, initializer)
    self.setting = initializer:GetSetting()
    self:SetSwatch(self.setting:GetValue())
    self.valueHandle = Settings.SetOnValueChangedCallback(self.setting:GetVariable(), function(_, _, value)
        self:SetSwatch(value)
    end)
end

function RogueEnergyCPColorControlMixin:Release()
    if self.valueHandle then
        self.valueHandle:Unregister()
        self.valueHandle = nil
    end
    SettingsControlMixin.Release(self)
end

function RogueEnergyCPColorControlMixin:OnSettingValueChanged(_, value)
    self:SetSwatch(value)
end

function RogueEnergyCPColorControlMixin:SetSwatch(hex)
    self.Swatch.Color:SetColorTexture(FromHex(hex))
end

function RogueEnergyCPColorControlMixin:OpenPicker()
    local setting = self.setting
    local r, g, b = FromHex(setting:GetValue())
    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b, hasOpacity = false,
        swatchFunc = function()
            setting:SetValue(ToHex(ColorPickerFrame:GetColorRGB()))
        end,
        cancelFunc = function(previous)
            setting:SetValue(ToHex(previous.r, previous.g, previous.b))
        end,
    })
end

function ns.SetupOptions()
    local bar, cp, vis = ns.ApplyEnergyBar, ns.ApplyComboPoints, ns.ApplyVisibility
    category, layout = Settings.RegisterVerticalLayoutCategory("Rogue Energy CP")

    Header("Energy bar")
    MediaDropdown("Texture", "texture", "statusbar", bar)
    ColorPicker("Normal color", "normalColor", bar)
    ColorPicker("Capped color", "cappedColor", bar)
    PercentSlider("Capped at", "cappedThreshold", 50, 100, bar,
        "Energy from which the bar uses the capped color.")
    MediaDropdown("Font", "font", "font", bar, "Font of the energy text. Its size is set in Edit Mode.")

    Header("Combo points")
    ColorPicker("Color", "cpColor", cp)

    Header("Visibility")
    PercentSlider("Out of combat alpha", "outOfCombatAlpha", 0, 100, vis,
        "Alpha of the bar out of combat once energy is full (0 hides it). "
        .. "It stays fully visible while energy is below the cap, in combat and in Edit Mode.")
    Checkbox("Show in stealth", "showInStealth", vis)

    Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
    if not category then
        print("|cff00ff00Rogue Energy CP:|r only works on rogues.")
        return
    end
    Settings.OpenToCategory(category:GetID())
end
