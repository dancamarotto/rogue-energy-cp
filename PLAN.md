# Plan

Energy bar + combo points for rogues, Forever only, configured through Options > AddOns
(appearance, visibility) and Edit Mode (size, layout, position).
See `CLAUDE.md` for the constraints (secret values, licensing) and the workflow.

## Status

| Stage | State |
|---|---|
| 0. Skeleton | done, confirmed in game |
| 1. Energy bar | done, confirmed in game |
| 2. Combo points | done, confirmed in game |
| 3. Edit Mode settings panel | done, confirmed in game |
| 3b. Fade only once energy is full, no Edit Mode label, combo points fade | done, confirmed in game |
| 3c. Options > AddOns page | done, awaiting in-game confirmation |
| 4. Polish and first release | next |

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
  in stealth (`UPDATE_STEALTH` + `IsStealthed()`), and in Edit Mode. Out of combat the bar
  stays at alpha 1 while energy is below the cap and fades over ~1s (OnUpdate) to
  `outOfCombatAlpha` (0 hides the frame) once energy is full; spending energy out of combat
  shows it again. Not configurable. The energy bar calls `ns.UpdateVisibility()` on every
  energy update out of combat. "Full" is `UnitPower >= UnitPowerMax` inside `pcall`; when
  that errors (secret energy, e.g. inside an instance) there is no fade: the frame stays shown
  and its alpha comes from `UnitPowerPercent("player", Energy, false, alphaCurve)` with a
  Step `C_CurveUtil.CreateCurve()` of points `(0, 1)` and `(1, outOfCombatAlpha)`.
  Edit Mode enter/exit call the same `ns.UpdateVisibility()`; the dialog calls
  `ns.ApplyVisibility()` (rebuilds the curve).
- Defaults to add: `texture = "Blizzard"`, `font = "Friz Quadrata TT"`, `fontSize = 14`,
  `textAlign = "CENTER"`, `showText = true`, `normalColor`, `cappedColor`, `cappedThreshold = 0.9`,
  `outOfCombatAlpha = 0`, `showInStealth = true`.

In-game test: bar follows energy out of combat, in combat and inside an instance (secret
values) with no errors; color changes near cap; text aligns; after combat it stays until energy
is full, then fades; Sprint out of combat shows it again; inside an instance out of combat it
disappears at full energy (no fade) and comes back when energy drops; stealth shows it;
Edit Mode shows it at full alpha.

## Stage 2. Combo points (done)

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
  false fades the row out (`ns.FADE_OUT`, 1s, same `ns.NewFader` as the energy bar in `Core.lua`)
  when `HasPoints()` turns false and fades it in (`ns.FADE_IN`, 0.2s) when it turns true
  (nil = secret → keep shown).
- Defaults: `cpSide = "ABOVE"`, `cpOffset = 2`, `cpStyle = "classic"`, `cpSize = 14`,
  `cpGap = 2`, `cpColor = {r=0.92, g=0.13, b=0.16}`, `cpShowEmpty = true`.

In-game test: dots fill 1..5 while building points on a target, in and out of instances;
reset on target change; row sits above/below the bar and resizes with it.

## Stage 3. Edit Mode settings panel (done)

In `EditMode.lua`, `LEM:AddFrameSettings(frame, {...})` after `AddFrame`. Since stage 3c it
holds only geometry and arrangement:

1. Bar: Width (slider 80-600), Height (8-60).
2. Text (divider): Show text (checkbox), Align (dropdown LEFT/CENTER/RIGHT), Size (slider 8-32).
3. Combo points (divider): Side (dropdown ABOVE/BELOW), Style (dropdown classic/silver/square/glow/flat/diamond),
   Size (slider 8-30), Gap (0-10), Distance (0-20), Show empty (checkbox).

`get` returns `ns.db[key]`; `set` writes it and calls the module's `Apply()`. Settings are
global (not per layout).

In-game test: every control applies live, Reset to Defaults restores `ns.defaults`,
values persist after reload.

## Stage 3c. Options > AddOns page (done)

The appearance and visibility settings moved out of Edit Mode into a native Settings page
(`Options.lua`, `Settings.RegisterVerticalLayoutCategory` + `RegisterAddOnCategory`), so the
addon follows the native components: colors and behavior in Options, layout in Edit Mode.
`/recp` opens the page (`Settings.OpenToCategory`); Edit Mode is opened the normal way.

Sections and controls, every one a `Settings.RegisterProxySetting` over `ns.db[key]` whose
setter calls the module's `Apply()`:

1. Energy bar: Texture (dropdown, LSM statusbar list), Normal color, Capped color (swatch),
   Capped at (slider 50-100 %), Font (dropdown, LSM font list).
2. Combo points: Color (swatch).
3. Visibility: Out of combat alpha (slider 0-100 %), Show in stealth (checkbox).

Percent sliders store 0-1 and expose 0-100. Colors are String settings holding `aarrggbb`
(the format of `ColorMixin:GenerateHexColor`) shown with the client's own
`Settings.CreateColorSwatch`, which opens the game's color picker and follows the setting, so
the panel's Defaults button resets it too. No preview: the bar is not
forced visible while the page is open (decided), so out of combat with full energy and alpha 0
the changes are only seen later.

In-game test: `/recp` opens Options > AddOns > Rogue Energy CP; every control applies live
(check with energy below the cap so the bar is visible); the long Texture/Font dropdowns fit
the screen; the color swatch opens the picker, Okay keeps and Cancel reverts; the panel's
Defaults button resets the page; Edit Mode shows only the layout settings and its Reset to
Defaults only touches those; values persist after reload.

## Stage 4. Polish and first release

README with screenshots, `/recp` help text, sanity pass on luacheck globals, tag `1.0.0`
(CI publishes the GitHub release). CurseForge/Wago upload only if the user adds the tokens
as repo secrets and the project IDs to the TOC.
