# Issue 37 combat color verification

Issue: https://github.com/sandervspl/BuffTimers/issues/37

The Always yellow option now overrides Blizzard's color on secret-duration updates,
including when compact-text support is absent. Multicolor still requires readable
remaining time. Its option description now explains the native-color fallback and
points to Always yellow for a consistent combat color. The issue is only partially
addressed; custom threshold colors during restricted durations remain unresolved.

## Repeatable local verification

Run from the repository root with Lua 5.1:

```sh
lua Tests/combat-color-replay.lua
bash scripts/sync-wow-ui-source.sh forever
lua Tests/forever-duration-replay.lua
```

Both replays passed on 2026-11-08 using Lupa's Lua 5.1 runtime. The combat replay
failed before the runtime fix and passed afterward. It covers readable to secret
and back, repeated native color resets, both color options enabled, disabling
yellow while secret, and missing compact-text support. The upstream replay passed
all scenarios after adding the current upstream InputUtil gamepad mock.

These replays do not emulate WoW's taint engine. In-game verification is pending:
enable both color options, apply long and short buffs plus a weapon enchant,
enter combat, cross a minute boundary, and leave combat. Confirm yellow throughout
and no Lua errors. Disable Always yellow and confirm native colors while restricted
and custom threshold colors once durations are readable again. Record client build,
profile, addon commit, and video covering the transitions.

## Upstream evidence

All branches were synchronized and inspected sequentially. In every branch,
`Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua`,
`AuraButtonMixin:UpdateDuration`, sets the native duration color on each update.

| Branch | Commit |
| --- | --- |
| live | 297d7aaaa736 |
| classic | e5d9b3a22c3f |
| classic_titan | 7014c309a253 |
| classic_anniversary | 68e0a2ec559d |
| classic_era | 4192ac60067f |
| forever | 9dc84f0d3bba |

Generated documentation consulted in live and/or forever:
`UnitAuraDocumentation.lua` (`GetAuraDuration`),
`LuaDurationObjectAPIDocumentation.lua` (`EvaluateRemainingDuration`),
`LuaColorCurveObjectAPIDocumentation.lua`, and `CurveUtilDocumentation.lua`.
The duration/curve APIs restrict secret arguments to untainted execution.
Forever's `SimpleFontStringAPIDocumentation.lua` documents `SetTextColor` as
AllowedWhenTainted; applying a fixed public color needs no secret arithmetic.
