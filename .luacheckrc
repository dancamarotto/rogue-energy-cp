std = "lua51"
max_line_length = false
exclude_files = { "**/Libs", ".release" }
only = {
    "011", -- syntax
    "1",   -- globals
}
ignore = {
    "11/SLASH_.*",            -- slash handlers
    "1/[A-Z][A-Z][A-Z0-9_]+", -- three letter+ constants
}
globals = {
    -- our own
    "RogueEnergyCP",
    "RogueEnergyCPDB",
    "RogueEnergyCPColorControlMixin",
    "SlashCmdList",

    -- wow api
    "C_CurveUtil",
    "ColorPickerFrame",
    "CopyTable",
    "CreateFrame",
    "CreateColor",
    "CreateFromMixins",
    "CreateSettingsListSectionHeaderInitializer",
    "Enum",
    "GetComboPoints",
    "GetTime",
    "IsStealthed",
    "LibStub",
    "MinimalSliderWithSteppersMixin",
    "Settings",
    "SettingsControlMixin",
    "UIParent",
    "UnitAffectingCombat",
    "UnitClass",
    "UnitPower",
    "UnitPowerMax",
    "UnitPowerPercent",
    "wipe",
}
