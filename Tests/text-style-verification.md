# Text customization restoration

The reported error occurs in `RestoreNativeDurationStyle` while replaying a saved
FontString anchor. Previously, the saved style was removed only after restoration
completed; a rejected `SetPoint` left it queued for every later duration update.
This explains the repeated errors after disabling customization. The exact rejected
in-game anchor arguments were not included in the report.

The fix consumes the snapshot before restoring it, supplies zero for omitted
offsets, and supplies the saved point when the relative point is omitted. If the
client rejects a saved region reference, it reconstructs Blizzard's default anchor
using the current aura icon and grid orientation/growth settings. A rejected saved
anchor therefore does not block restoration of other durations, fonts, or layers.

`lua Tests/text-style-replay.lua` exercises valid and omitted offsets, a deliberately
rejected relative region, a layout change during customization, multiple durations,
120 subsequent update rounds, and a second enable/disable cycle. The pre-fix replay
failed in `BuffTimers.lua:95` on omitted offsets. The fixed replay passes for all
six supported client configurations. Output is in `text-style-replay-output.txt`.
This simulates frame validation and does not emulate WoW's taint engine.

Also passed: the native/options lifecycle replay for Retail and Forever, and
`Tests/forever-duration-replay.lua` against Blizzard's checked-out Forever source.

In-game confirmation: reload, open BuffTimers options, disable text customization,
and leave the aura timers updating. Check for no further errors and restored
default positioning/font. Re-enable customization and disable it again. Repeat
after changing grid orientation, and with both a buff and weapon enchant present.
The reported in-game scenario has not yet been rechecked with this fix.

Upstream inspected sequentially: `live` `297d7aaaa736`, `classic` `e5d9b3a22c3f`,
`classic_titan` `7014c309a253`, `classic_anniversary` `68e0a2ec559d`,
`classic_era` `4192ac60067f`, and `forever` `bebcb6bf309c`.
Main references: `Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua`
(`AuraContainerMixin:UpdateGridLayout` and locale duration anchoring), and
`BuffFrameTemplates.xml` (default duration anchor). Retail's
`Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua` and `ScriptAnimationUtil.lua`
were also consulted for the standard five-value `GetPoint`/`SetPoint` convention.
