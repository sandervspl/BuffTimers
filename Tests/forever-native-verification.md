# Native buff mode verification: Retail and Forever

## Confirmed native rendering path

On 2026-11-14, the user tested the separate native-container probe on Forever
1.60.1 build 70938 (interface 16001). They reported that the real long buff stayed
at `91m` during combat, rather than changing to hours. SavedVariables recorded
combat entry at elapsed 2963537.192 and exit at 2963545.696, followed by stopping
the probe at 2963547.349. The synthetic formatter samples included `6300 = 105m`
and `6301 = 106m`.

This is a successful combat-entry smoke check for native minutes rendering. It
does not establish minute-boundary countdowns, refreshes during combat, debuff
time modifiers, or the production integration's layout and interactions on its own.

After the opt-in integration was installed through commit `b4dfa90`, the user
reported "it works" in response to the `/reload`, `/btnative on`, and real-buff
combat verification instructions. This confirms a successful in-game check of
the integrated mode for the reported minutes-only profile on 2026-11-14. The
user did not separately describe refreshes, exact minute transitions, or every
layout/interaction case; the extended checklist below remains useful coverage.

## Native integration

`NativeAuras.lua` provides the shared experimental buff renderer for Retail
(interface 120105) and Forever (16001). It starts enabled when no preference has
been saved. Open BuffTimers options (`/bufftimers`), then **Time > Combat timers**.
The **Use replacement buff renderer** toggle enables or disables the renderer outside
combat. A status message appears only when the renderer is paused or unavailable;
the toggle itself shows the normal enabled/disabled state.
The `/btnative` command has been removed. The choice persists separately in `BuffTimersNativeDB`;
profile import/export is unaffected. The choice is stored separately by each
installed client. An existing saved `enabled = false` remains disabled; use
the options toggle outside combat to re-enable it. Other supported clients return before creating the module or
accessing native aura-container APIs. A supported client missing the required
native APIs keeps the original renderer; its options toggle is disabled and the
status explains the limitation. The control is hidden on other Classic clients.

Retail support is source-checked and covered by the lifecycle replay. It has not
yet been verified in Retail combat; the user-confirmed in-game results above
apply to Forever. The same options control and supported profile restrictions
apply to both clients.

Both time formats, seconds and their threshold, milliseconds, detailed hover,
color settings, text customization, font/size/outline/position, and profile
changes are supported by the replacement renderer. Expanded buffs and
mouse/keyboard navigation are still required. Detailed hover uses the native
highlight overlay described below. Unsupported WoW navigation/display modes
produce an explicit chat message and restore the existing renderer. Edit Mode
temporarily uses Blizzard's existing buttons. Settings changed during combat
apply after combat. Native mode is on by default; the original renderer remains
available through the options toggle.

The container is anchored at the existing buff frame and follows its orientation,
growth, stride, padding, scale, and BuffTimers font/position/color settings. It
draws buff icons, stacks, weapon enchants, native tooltips, cancellation and native
duration text. Native aura updates own all duration changes; no precombat times
or aura identifiers are cached. Original buff buttons keep running for host
layout but become transparent and stop receiving mouse input. Debuffs and private
aura anchors retain the existing renderer. Buffs use native aura-instance ordering;
exact ordering parity with Blizzard's legacy display is not asserted.
The host reserves fixed capacity for the full buff group plus three weapon
enchant slots, so a full grid cannot overrun the legacy host's allocation. This
can reserve an extra row/column compared with the original frame; the host returns
to its original capacity when native mode stops. Native mode can be disabled
in the options menu.

Native text uses NumericRuleFormatter so the binding can render tenths with `s`,
ceil whole minutes, and days at 24 hours, without addon arithmetic on secret times.
Enabling checks the actual native formatter's public 6300/6301-second results
before suppressing the existing display. Any caught setup error disables native
mode and restores the original buttons. The user has now confirmed that the
integrated mode works in-game. This is distinct from the earlier successful
probe, which used SecondsFormatter and a separate panel, and does not establish
that every case in the extended checklist has been tested.

## Repeatable integration check

The local lifecycle replay is `lua Tests/forever-native-replay.lua`. It checks
other-client guards, suppression after native alpha updates, combat-deferred
configuration, profile fallback/reactivation, layout settings, the duration CVar,
Edit Mode, opt-out, and formatter-failure rollback. It uses simulated frame APIs
and native rule evaluation; it cannot prove WoW security or native formatting.
Its output is saved in `Tests/forever-native-replay-output.txt`. The replay also
checks missing-API fallback. Run it in separate Lua VMs with
`BUFFTIMERS_TEST_INTERFACE` set to 120105 and 16001 to cover both supported paths.

On this Windows machine the equivalent runner is:

```powershell
@'
from pathlib import Path
from lupa.lua51 import LuaRuntime
source = Path('Tests/forever-native-replay.lua').read_text(encoding='utf-8')
for interface in (120105, 16001):
    print('CLIENT', interface, flush=True)
    vm = LuaRuntime()
    vm.globals().BUFFTIMERS_TEST_INTERFACE = interface
    vm.execute(source)
'@ | python -
```

The normal `busted` launcher cannot run here because it requires an installed WSL
distribution. The focused lifecycle replay and Lua 5.1 parsing were run instead;
the full Busted suite was not run for this integration.

1. Reload, open `/bufftimers`, and enable **Time > Combat timers > Use native buff
   timers** outside combat. Check the status. Verify the buffs stay at your normal buff-frame location,
   use your configured font/position, and show stacks and weapon enchants.
2. With a buff above 90 minutes, enter combat and stay across a minute boundary.
   Refresh it and gain/remove other buffs while fighting. Verify current values
   and no duplicate icons/text. Include an untimed aura and a short buff expiring.
3. Leave combat, change font/position, duration CVar, color and milliseconds. Enter
   Edit Mode; try horizontal/vertical layout, both growth directions, stride,
   padding and scale. Check previews and restored live buffs.
4. Collapse buffs or enable gamepad navigation. Check
   the explicit message and original display. Restore the supported settings and
   verify native mode returns. Repeat profile changes during combat and check
   they apply after leaving combat.
5. Disable native timers in options; verify normal icons, mouse interactions and tooltips return.
   Enable native mode again, reload, and repeat combat entry. Save a video with
   build, settings and any Lua errors as the visual verification artifact.

## Source evidence

Inspected `live` at `297d7aaaa736` and then `forever` at `bebcb6bf309c`
sequentially with the sync helper, including
`Blizzard_BuffFrame/BuffFrame.lua`, `BuffFrameTemplates.xml`,
`Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`,
`Blizzard_CustomAuraButton.lua`, `Blizzard_AuraButton.lua/.xml`,
`Blizzard_AuraContainerUtil.lua`, `Blizzard_AuraContainerFlowLayout.lua`, and generated
`NumericRuleFormatter`, `LuaColorCurveObject`, `DurationTextBinding` and `UnitAura`
API definitions. Custom aura-button/container implementations and the relevant
formatter, color-curve, and duration-binding definitions match between these
two snapshots; the legacy buff host uses the same layout sizing formula. The
research notes contain immutable links. No conclusions are drawn for the other
Classic branches beyond the module's tested early return.

## Detailed hover integration

Detailed hover no longer selects the legacy renderer. When enabled, a second
native container uses identical filters, aura-instance ordering, enchant slots,
grid dimensions, growth and scale. It draws only a detailed timer, without a
background. Each timer has a separate opacity parent underneath its native aura
button. An addon-owned sibling hit region follows that button's geometry. An
unanchored update driver forwards the hit region's potentially secret
`IsMouseOver()` result directly to `SetAlphaFromBoolean`, selecting complementary
opacity for compact and detailed labels. Lua never branches on that result.
The compact timer continues counting while hidden. Below one minute, the hover
formatter renders the same seconds/tenths as the compact timer.

The overlay has no icons/stacks, no addon scripts or queries on native buttons,
and no aura cancellation action. Native buttons propagate input, so only the main
renderer handles right-click cancellation. Native tooltips remain engine-owned.
Both containers receive live aura assignments and durations from Blizzard;
there is no precombat duration cache or addon comparison of secret timer values.
The overlay is disabled when duration display, detailed hover, or the replacement
renderer is disabled. Font/profile/layout changes still apply outside combat.

The lifecycle replay models native alpha selection using opaque mouseover tokens
and exercises 6300,
3600, 3599.9, 60, 59 and 4.9 seconds, leaving hover, refresh while hovered,
another unhovered buff, toggling hover, duration visibility, combat-deferred
configuration, native font changes, and vertical layout. It supplies neither
OnEnter/OnLeave nor mouse-focus query methods to the simulated aura buttons.
It checks that hovering in combat hides the compact label, leaving restores it,
other buffs remain compact, and no background texture is created. Short timers
are checked with tenths both enabled and disabled. This verifies addon
configuration and native API contracts, not the client's security engine.
The new opacity parents and hit-region anchoring need in-game confirmation.

Recheck in-game: enable **Show detailed time on hover** before combat, hover a
long buff and verify `hh:mm:ss`, then leave it and verify compact minutes. Enter
combat and repeat, refresh that buff, and cross a minute boundary. Check a short
buff below 60 seconds, weapon enchants, native tooltips and one right-click
cancellation. Verify there is no visible overlap of the two labels and that
disabling hover restores compact native timers without restoring legacy buttons.

For this path, inspected `live` `297d7aaaa736` followed by `forever` `bebcb6bf309c`:
`Blizzard_AuraButton.xml`, `Blizzard_AuraContainerFrameProviders.lua`,
`Blizzard_AuraContainerUtil.lua` and `SimpleFrameScriptObjectAPIDocumentation.lua`
for per-object access restrictions and descendant binding validation;
`Blizzard_CustomAuraButton.lua` for native duration text/color binding;
`SimpleScriptRegionAPIDocumentation.lua` for secret geometric hit testing;
`SimpleFrameAPIDocumentation.lua` for secret-safe alpha selection; and
`Blizzard_SharedXMLBase/ForbiddenAspectTemplates.xml` for explicit hierarchy and
layout script restrictions. The text parents opt into both script restrictions;
the sibling hit regions need only the layout restriction. No native button is
accessed by the hover update driver.

For the shared options-menu change, all supported branches were also inspected
sequentially: `live` `297d7aaaa736`, `classic` `e5d9b3a22c3f`, `classic_titan`
`7014c309a253`, `classic_anniversary` `68e0a2ec559d`, `classic_era` `4192ac60067f`,
and `forever` `bebcb6bf309c`. The main references were
`Blizzard_BuffFrame/Blizzard_BuffFrame.toc` and `BuffFrame.lua` for each client,
plus `Blizzard_AuraContainer.lua` for the two native clients. Classic keeps its
existing timer path; the new options group queries the native module silently
and hides itself when that module is absent.

## Native formatting options

The normal native formatter builds breakpoints from the current profile:
minutes (`105m`) or hours/minutes (`1:45h`), seconds below the selected threshold
(`105:00` or `1:45:00`), optional tenths below five seconds, and days after 24
hours. It rounds the complete input up to the minute before splitting h:mm, so
the minute component cannot become `60`. The native h:mm presentation is
canonical: a rounded whole hour is `2:00h` rather than the legacy renderer's
occasional `2h` shorthand; below one hour it uses minutes. Its day policy follows
the existing formatter's completed-hour calculation. All actual remaining-time
selection, rounding, division and modulo take place in the native formatter.

The formatting signature includes format, seconds and threshold settings, so
changing them rebuilds the native formatter. Updates requested during combat
apply after combat. Hover uses its independent detailed formatter with all normal
format configurations. Native color curves handle the existing red/yellow/green
bands and always-yellow precedence. The color option's restriction warning is
shown only when the original renderer is active.

The replay drives actual options callbacks across both formats, thresholds 1,
30, 60 and 120 minutes, seconds on/off, tenths on/off, hour/minute/day boundaries,
hover, all outline choices, font/size/position, customization off/on, color bands
and precedence, profile table changes, and combat-deferred format changes. It
still checks gamepad/collapsed fallback, Edit Mode, opt-out and error rollback.
Output is recorded in `forever-native-replay-output.txt`. These are native API
contract simulations; the added formatting combinations need in-game checking.

Inspected `live` `297d7aaaa736` followed by `forever` `bebcb6bf309c` for this
change: generated `NumericRuleFormatterSharedDocumentation.lua` and
`NumericRuleFormatterAPIDocumentation.lua` describe breakpoint selection, input
rounding and component div/mod/rounding. Existing BuffTimers `FormatTime` and its
formatting cases were consulted for the option semantics and day policy.

## Temporary enchant icons

The native item-enchantment aura data does not include an icon, so its default
icon setter uses the equipped weapon texture. Forever's stock BuffFrame instead
uses `C_Item.GetWeaponEnchantInfo(...).enchantIconID` when the
`displayTemporaryEnchantIcon` preference is enabled. This caused the shaman imbue
to appear as a hammer rather than its spell icon in the replacement renderer.

On clients exposing that API, fixed enchant slots now have addon-owned icon
frames anchored to the native slot's icon proxy. They opt into
`DisableUntrustedLayoutScriptsTemplate` and do not query the native slot's secret
coordinates or visibility. Public weapon-enchant metadata supplies the selected
icon, matching the enchant ID chosen by the native duration renderer. With the
spell-icon preference off, the equipped weapon texture is used. Slots without
an active enchant hide their icon, and disabling the replacement hides all these
frames through an independent parent with no native layout anchors. Updates also
run during combat when both the icon frame and texture are accessible. If either
access check is denied or secret, the last icon is retained until access returns.
Clients without the spell-icon API retain the existing native inventory icon.
No buff ordering changes are included.

The replay covers spell-icon preference on/off, re-imbuing during combat, two
active enchant types with one preferred duration, enchant removal, dual wield,
inactive slots, opt-out cleanup and the client without this API. The output is
in `forever-native-replay-output.txt`. Real-client anchoring and appearance still
need confirmation: reload, compare the shaman imbue icon with the replacement
on/off, refresh/change the imbue in combat, and test both weapon slots if used.

Inspected `forever` `bebcb6bf309c` and `live` `297d7aaaa736` sequentially:
`Blizzard_BuffFrame/BuffFrame.lua` (stock enchant icon preference),
`Blizzard_AuraContainer/Blizzard_AuraContainerEnchantments.lua` and
`Blizzard_AuraContainerUtil.lua` (native data and weapon-texture fallback),
`ItemDocumentation.lua` (`WeaponEnchantInfo`), `PaperDollInfoDocumentation.lua`
(`GetTemporaryEnchantmentInfo`, imbue priority), and
`Blizzard_SharedXMLBase/ForbiddenAspectTemplates.xml` (safe layout opt-in).

## Forbidden icon recovery

The reported error was a second failure in recovery: `SafeRefresh` caught an
update error, then `Restore` called `Hide` on a forbidden enchant frame before
the saved enabled flag or active flag could be cleared. Every ticker pulse could
repeat that sequence. The prior replay treated all independently created frames
as permanently accessible, which missed this failure mode.

`CanBeAccessedInContext` now gates enchant frame/texture writes and the complete
hover opacity swap. A secret access-check result is rejected with
`issecretvalue` before any Lua boolean branch. A blocked hover swap retains both
labels' previous opacity, preventing a partial swap from showing both labels.
The enchant frames share an unanchored parent, so restoring the original display
can hide their parent without calling methods on the individual forbidden
frames. The supplied UI source documents access restrictions but does not expose
the engine's complete frame/anchor propagation rules; the user's trace establishes
that retaining an addon-created icon frame did not guarantee access in this case.

Native reconfiguration and restoration wait for both combat lockdown and
`C_Secrets.ShouldAurasBeSecret()` to end. On an actual update error, the disabled
preference and inactive state are set before protected cleanup. Subsequent
ticks finish deferred restoration without repeating the stop message. Original
buttons remain suppressed until that restoration completes, preventing duplicate
art while native countdown bindings continue to run.

The extended replay rejects all mutations on simulated forbidden objects. It
checks a forbidden icon outside combat, secret texture access, icon catch-up,
opt-out with a forbidden child, a blocked hover swap, and aura restrictions after
combat. It also injects an independent metadata error during combat while another
icon is forbidden, repeats ticker/hover updates, keeps aura restrictions active
after combat, then verifies restoration and successful re-enabling. These are API
contract simulations; real-client security behavior still needs `/reload` and an
in-game combat/opt-out check. Output is in `forever-native-replay-output.txt`.

Inspected `live` `297d7aaaa736` followed by `forever` `bebcb6bf309c` for this fix:
`Blizzard_AuraContainerFrameProviders.lua` (restrictions applied after frame
initialization), `Blizzard_CustomAuraButton.lua` (descendant region binding),
`SimpleFrameScriptObjectAPIDocumentation.lua` (`CanBeAccessedInContext`, secret
security results), `SecretPredicateAPIDocumentation.lua` (`ShouldAurasBeSecret`),
and `Blizzard_SharedXMLBase/ForbiddenAspectTemplates.xml` (layout restrictions).
