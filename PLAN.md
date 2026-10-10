# Plan

Energy bar + combo points for rogues, Forever only, configured only through Edit Mode.

## Constraints

- Forever returns energy and combo points as **secret values** in combat and
  instances: no reading, comparing or arithmetic. Energy goes straight into
  `StatusBar:SetValue` / `FontString:SetText`; the bar color comes from
  `UnitPowerPercent` with a color curve. Each combo point is a StatusBar with
  range (i-1, i) fed with the raw value, so dot i fills at i or more points.
- No energy ticker: it needs value comparisons.
- NugEnergy is All Rights Reserved: reference for techniques only, no copied
  code or textures. Combo Points on Plate is MIT: textures reused with notice.

## Stages

0. Skeleton: repo, CI (luacheck + packager), libs, placeholder frame placed via Edit Mode. ✔
1. Energy bar: statusbar, text (left/center/right), color curve, visibility (combat, stealth, fade out of combat).
2. Combo points: row of dots above or below the bar, CPoP styles and color.
3. Edit Mode settings panel: width, height, texture, font, text alignment, colors, combo point options.
4. Polish: README, first tagged release.

## Settings (all in the Edit Mode panel)

Bar: width, height, texture, normal color, capped color.
Text: show, align (left/center/right), font, size.
Combo points: side (above/below), style, color, size, gap, distance from bar.
Visibility: out of combat alpha, show in stealth.
