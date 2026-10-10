# Plan

Energy bar + combo points for rogues, Forever only, configured only through Edit Mode.
See `CLAUDE.md` for the constraints (secret values, licensing) and the workflow.

## Status

| Stage | State |
|---|---|
| 0. Skeleton | done, confirmed in game |
| 1. Energy bar | done, awaiting in-game confirmation (build test-20261010-205200) |
| 2. Combo points | next |
| 3. Edit Mode settings panel | pending |
| 4. Polish and first release | pending |

## Stage 0. Skeleton (done)

Repo, CI (luacheck on push, packager release on tags), libs via `.pkgmeta`
(LibStub, CallbackHandler, LibSharedMedia, LibEditMode), MIT license, CPoP textures,
`Core.lua` with db + `/recp` (opens Edit Mode) + `/recp reset`, `EditMode.lua` with position
per layout (enter/exit/layout/create/rename/delete callbacks). The frame is a dark placeholder.

In-game test: loads without errors on a rogue; `/recp` shows the frame in Edit Mode; drag,
reload, position kept; each layout keeps its own position; `/recp reset` centers; nothing on
a non-rogue.

## Stage 1. Energy bar (done)

New `EnergyBar.lua`. Replace the placeholder with:

- A `StatusBar` filling `ns.frame`, texture from LibSharedMedia (`statusbar`), dark background
  texture behind it, 1px border optional.
- Events on a child frame: `UNIT_POWER_UPDATE` and `UNIT_POWER_FREQUENT` (unit "player",
  only when powerType == "ENERGY"), `UNIT_MAXPOWER` → `SetMinMaxValues(0, UnitPowerMax("player", Enum.PowerType.Energy))`.
- Update: `bar:SetValue(UnitPower("player", Enum.PowerType.Energy))` and
  `text:SetText(UnitPower(...))` raw (secret-safe). Color:
  `local c = UnitPowerPercent("player", Enum.PowerType.Energy, false, colorCurve); bar:SetStatusBarColor(c:GetRGBA())`.
  Curve: `C_CurveUtil.CreateColorCurve()`, `SetType(Enum.LuaCurveType.Step)`, points
  `(0, normalColor)` and `(cappedThreshold, cappedColor)`; rebuild when colors change.
- Text: one FontString, font from LibSharedMedia (`font`), size and outline, anchored
  LEFT / CENTER / RIGHT of the bar with a small inset.
- Visibility (`Core.lua`): shown at alpha 1 in combat (`PLAYER_REGEN_DISABLED/ENABLED`),
  in stealth (`UPDATE_STEALTH` + `IsStealthed()`), and in Edit Mode. Otherwise alpha =
  `outOfCombatAlpha` (0 hides the frame). Fade out over ~1s with an OnUpdate when leaving
  combat. Edit Mode enter/exit call the same `ns.UpdateVisibility()`.
- Defaults to add: `texture = "Blizzard"`, `font = "Friz Quadrata TT"`, `fontSize = 14`,
  `textAlign = "CENTER"`, `showText = true`, `normalColor`, `cappedColor`, `cappedThreshold = 0.9`,
  `outOfCombatAlpha = 0`, `showInStealth = true`.

In-game test: bar follows energy out of combat, in combat and inside an instance (secret
values) with no errors; color changes near cap; text aligns; fades after combat; stealth shows it;
Edit Mode shows it at full alpha.

## Stage 2. Combo points

New `ComboPoints.lua`. A row frame anchored to the top or bottom of `ns.frame`
(`cpSide = "ABOVE" | "BELOW"`, `cpOffset` distance), horizontally centered.

- 5 dots (`UnitPowerMax("player", Enum.PowerType.ComboPoints)` read inside pcall, default 5).
  Each dot: a Frame with an `empty` texture (`Textures/<style>_empty`) and a child StatusBar
  with `SetMinMaxValues(i-1, i)` and `Textures/<style>_full` as bar texture, colored with
  `cpColor`. Styles with `tintEmpty` (glow, flat, diamond) tint the empty texture too.
- Feed: `bar:SetValue(GetComboPoints("player", "target"))` for every dot on
  `UNIT_POWER_UPDATE` (powerType "COMBO_POINTS"), `PLAYER_TARGET_CHANGED`, `PLAYER_ENTERING_WORLD`,
  plus a light OnUpdate throttle (0.1s) as safety net, like CPoP.
- Shown whenever the energy bar is shown; `cpShowEmpty = true` keeps empty sockets visible,
  false hides the row when `HasPoints()` is false (nil = secret → keep shown).
- Defaults: `cpSide = "ABOVE"`, `cpOffset = 2`, `cpStyle = "classic"`, `cpSize = 14`,
  `cpGap = 2`, `cpColor = {r=0.92, g=0.13, b=0.16}`, `cpShowEmpty = true`.

In-game test: dots fill 1..5 while building points on a target, in and out of instances;
reset on target change; row sits above/below the bar and resizes with it.

## Stage 3. Edit Mode settings panel

In `EditMode.lua`, `LEM:AddFrameSettings(frame, {...})` after `AddFrame`. Order:

1. Bar: Width (slider 80-600), Height (8-60), Texture (dropdown from LSM list),
   Normal color (ColorPicker), Capped color (ColorPicker), Capped at (slider 50-100 %).
2. Text (divider): Show text (checkbox), Align (dropdown LEFT/CENTER/RIGHT), Font (dropdown LSM),
   Size (slider 8-32).
3. Combo points (divider): Side (dropdown ABOVE/BELOW), Style (dropdown classic/silver/square/glow/flat/diamond),
   Color (ColorPicker), Size (slider 8-30), Gap (0-10), Distance (0-20), Show empty (checkbox).
4. Visibility (divider): Out of combat alpha (slider 0-100 %), Show in stealth (checkbox).

`get` returns `ns.db[key]`; `set` writes it and calls the module's `Apply()`. Settings are
global (not per layout). ColorPicker get/set use ColorMixin (`CreateColor`), store r/g/b.

In-game test: every control applies live, Reset to Defaults restores `ns.defaults`,
values persist after reload.

## Stage 4. Polish and first release

README with screenshots, `/recp` help text, sanity pass on luacheck globals, tag `1.0.0`
(CI publishes the GitHub release). CurseForge/Wago upload only if the user adds the tokens
as repo secrets and the project IDs to the TOC.
