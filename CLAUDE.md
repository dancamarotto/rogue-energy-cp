# Rogue Energy CP

WoW addon: energy bar with combo points for rogues, **WoW Forever only** (Interface 16001),
configured **only through the game's Edit Mode** (LibEditMode). Plain SavedVariables
(`RogueEnergyCPDB`), no Ace libs. The plan, stage status and technical design live in `PLAN.md`;
read it first and keep it updated when a stage completes.

## Hard constraints

- **Secret values.** In combat and in instances Forever returns energy and combo points as
  secret values: no reading, comparing or arithmetic, or the call errors. Feed them raw into
  `StatusBar:SetValue` / `FontString:SetText`; get colors from
  `UnitPowerPercent("player", powerType, false, colorCurve)` with a `C_CurveUtil.CreateColorCurve()`
  of type `Enum.LuaCurveType.Step`; each combo point is a StatusBar with range (i-1, i) fed with
  `GetComboPoints("player", "target")`. Wrap any numeric read in `pcall` and accept `nil`.
- **No energy ticker** (needs value comparisons).
- **Licensing.** `../NugEnergy` (rgd87) is All Rights Reserved: reference for techniques and API
  usage only, never copy code or textures from it. `../reference/ComboPointsOnPlate` is MIT:
  its textures are reused (notice in `Textures/`), its techniques may be reused.
- Never `hooksecurefunc` Blizzard frames on Forever (protected code calling hooked methods fails).

## Workflow

- One stage per session, in `PLAN.md` order. Each stage ends with a build the user tests in game.
  WoW is **not** installed on this Mac; the user tests on Windows. Claude cannot run the game.
- Build: `../rogue-energy-cp-build/build.sh` packages into `.release/` (gitignored);
  `../rogue-energy-cp-build/build.sh publish` also uploads the zip as a GitHub pre-release
  (tag `test-<date>`), which the user downloads on Windows. Needs Homebrew bash 5 and svn (installed).
- Before every commit: `luacheck . --no-color -q` must report 0 warnings (CI runs it too).
  Add any new WoW API global to `.luacheckrc`.
- `Libs/` is gitignored and comes from `.pkgmeta` at package time. Never commit it.
- Commits: small, one per stage, imperative subject, body with what changed for the user.
  End commit messages with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Releases: pushing a numeric tag (e.g. `1.0.0`) makes CI package and publish a GitHub release.

## Code conventions

- 4 spaces, double quotes, `local ADDON, ns = ...` per file, modules talk through `ns`.
- Files: `Core.lua` (db, events, visibility), `EnergyBar.lua`, `ComboPoints.lua`,
  `EditMode.lua` (position per layout + settings dialog). Add new files to `RogueEnergyCP.toc`.
- Settings are account wide in `ns.db`; only the position is per Edit Mode layout
  (`ns.db.layouts[layoutName]`). Defaults in `ns.defaults`, merged by `CopyDefaults` on load.
- Keep the settings few: the Edit Mode dialog is the whole UI.
