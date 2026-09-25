# Forever duration verification

## Automated replay

From the repository root:

```sh
bash scripts/sync-wow-ui-source.sh forever
lua Tests/forever-duration-replay.lua
busted
```

The replay loads Blizzard's actual `Blizzard_BuffFrame/BuffFrame.lua` with simulated
frame APIs. It covers direct duration updates, minute boundaries, weapon enchants,
debuffs with `timeMod`, visibility, button reuse, and edit previews. The separate
secret-duration cases check compact native text and clients without the string API.
These local tests do not emulate WoW's security or taint engine.

The user's in-game diagnostic on Forever 1.60.1 (70009) confirmed secret timer
values: `243.66 true 5 m` and `582.109 true 10 m`. The old addon deliberately skipped
formatting for those secret values. An attempted direct native numeric formatter
call then failed because it accepts secret numbers only during untainted execution.

The final fix retains the original duration hooks and passes Blizzard's already
rendered text through `C_StringUtil.RemoveContiguousSpaces(text, 0)`. This API
explicitly permits secret arguments during tainted execution. The addon never
reads or performs arithmetic on the secret timer. Missing API support leaves
Blizzard's text intact.

**Limitation:** while the timer is secret, its units, precision, and duration-based
color remain Blizzard's choices. Only spacing and the existing font/position
customization apply. Full custom hours, seconds, tenths, and color thresholds resume
when the timer becomes readable. This change does not promise those richer formats
for secret values.

On 2026-09-25 the user reported that the installed compact-text version appears
fixed in-game. Inspection of the installed file confirmed which implementation was
tested. The unverified duration-object implementation and unused formatter/curve
code were removed. The final cleanup preserves the working secret-text path; repo
and installed runtime were then synchronized. All 68 remaining tests and the
upstream replay passed. The broader scenario matrix below remains unverified.

## Extended in-game check (not yet completed)

1. Install this checkout in Forever and reload the UI. Enable Lua errors. Use
   minutes-only formatting, custom text positioning/font, and duration display.
2. Apply a 30-minute buff and a temporary weapon enchant. Enter combat before
   the buff reaches 29 minutes and stay in combat across that transition.
3. While fighting, gain/remove other buffs so the aura buttons change contents.
   Verify the original buff and enchant show `29m`, without a space, and retain
   their custom style. Continue across another minute boundary.
4. Leave combat without reloading. Verify formatting persists. Refresh the buff,
   then remove it and gain another timed buff. Check that its timer is current.
5. Disable duration display and verify timers stay hidden; re-enable it. Check
   an untimed buff, then enable seconds/milliseconds and watch a short buff expire.
6. Enter/leave Edit Mode and toggle text customization off/on. Check previews and
   restored native styling, then repeat a minute boundary during combat.

Record the client build, addon revision, active profile, any Lua error, and a video
covering combat entry, the minute transitions, and combat exit. Save the replay
output with that recording so the result can be reviewed and repeated.

## Upstream references inspected

All six supported branches were inspected sequentially. In each branch the main
reference was `Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua`, specifically
`AuraButtonMixin:OnUpdate`, `UpdateDuration`, and the duration update/script setup.

| Branch | Commit |
| --- | --- |
| live | `09b9db7948ab` |
| classic | `cde55d0033e8` |
| classic_titan | `84ef503f0d26` |
| classic_anniversary | `1463c686270b` |
| classic_era | `33e177d9bf38` |
| forever | `bd2470aed543` |

Forever's `BuffFrameTemplates.xml` and generated `UnitAuraDocumentation.lua` were
also consulted for script registration and aura restrictions. The final secret-text
path uses `StringUtilDocumentation.lua` (`RemoveContiguousSpaces`, explicitly
`AllowedWhenTainted`) and `SimpleFontStringAPIDocumentation.lua` (`GetText`/`SetText`).
`NumericFormatterAPIDocumentation.lua` documents why the rejected direct formatter
call is forbidden from addon code with secret input. Duration-object and color-curve
APIs were investigated, but are not used in the final patch.
