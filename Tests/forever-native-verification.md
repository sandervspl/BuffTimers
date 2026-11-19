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

## Expiration warning

The replacement now supplies the missing warning through its native duration
color curve: below 31 seconds it fades between alpha 0.3 and 1 with a 1.5-second
cycle. A step curve samples the cosine-shaped alpha waveform at 8 Hz using only
fixed public values, preserving the established step-based RGB color policy.
The native binding samples live remaining duration, so Lua never
reads, compares, or performs arithmetic on an aura's protected duration. Each
aura's phase follows its own remaining duration; Blizzard's legacy renderer uses
a shared fader. Existing text-color thresholds remain exact at 60 and 600 seconds.

Compact and hover text receive this alpha directly from their native bindings.
The update driver forwards the compact FontString's color alpha to icon, stack,
enchant image and border regions using secret-capable alpha setters. It checks
access first and skips forbidden objects. An invisible, native-bound Cooldown
provides a secret shown flag to the alpha setter so permanent assignments restore
full icon opacity, even if a disabled zero-duration text binding retains its old
color. The cooldown draws nothing and has zero opacity. Its duration is set and
refreshed only by Blizzard's custom aura-button implementation.

The compact text binding remains active when duration numbers are disabled,
while its FontString is hidden. This preserves icon warnings independently of
the duration CVar. Hover visibility and formatting keep their existing behavior.

The replay checks smooth interpolation, threshold edges, repeating cycles,
opaque alpha/visibility forwarding during combat, stacks, both enchant API paths,
refreshes, permanent slot reuse, denied region access, detailed hover text and
hidden duration numbers. Existing profile/color/lifecycle checks also pass.
The replay models individual region access separately from the native button's
restriction, and explicitly denied regions remain inaccessible. Output is in
`forever-native-replay-output.txt`. Actual native binding updates on hidden text,
cooldown visibility for zero-duration assignments, and combat access to retained
regions still require the real-client check: reload, let a short buff cross 31
seconds, hover it, refresh it in combat, and check a temporary weapon enchant.

Inspected `live` `297d7aaaa736` then `forever` `bebcb6bf309c`:
`Blizzard_BuffFrame/BuffFrame.lua` and `BuffFrameTemplates.xml` for warning timing
and alpha; `Blizzard_CustomAuraButton.lua` for native duration/color/cooldown
bindings and zero-duration handling; `LuaCurveObjectConstantsDocumentation.lua`
and `LuaColorCurveObjectAPIDocumentation.lua` for cosine interpolation;
`SimpleFontStringAPIDocumentation.lua` for secret color alpha; and
`SimpleRegionAPIDocumentation.lua` plus `FrameAPICooldownDocumentation.lua` for
secret-safe display setters and native cooldown updates.

## Duration text color correction

The user reported white text on long buffs after the expiration-warning change.
Their saved Default profile has neither always-yellow nor colored-text overrides,
so long timers should remain yellow. The warning change had switched the native
color curve from Step to Cosine. The UI mirror documents the API but does not
contain its engine implementation; the precise reason for the real-client color
failure is not established by the local replay.

The renderer now uses Step again, keeps the original RGB bands, and samples only
the warning alpha at 8 Hz. This removes both cosine interpolation of RGB values
and nearly coincident color-transition points. It validates the actual native
curve with public 6300, 31 and 30.25-second samples before hiding Blizzard's
display. Incorrect native color/alpha evaluation triggers the existing fallback.
No saved color preferences are changed.

The replay checks long-buff yellow, existing red/yellow/green and always-yellow
options, warning alpha, hover and hidden-number behavior. An injected native
all-white result verifies color-check failure restores the original display.
Real-client color/animation still requires `/reload` and an in-game check.

Inspected `live` `297d7aaaa736` then `forever` `bebcb6bf309c`:
`LuaColorCurveObjectAPIDocumentation.lua` (`AddPoint`, `EvaluateUnpacked`),
`LuaCurveObjectBaseAPIDocumentation.lua` and
`LuaCurveObjectConstantsDocumentation.lua` (curve types), and
`Blizzard_CustomAuraButton.lua` (native duration color binding).

## Optional blinking

Time > Combat timers now includes **Blink expiring buffs**, enabled by default.
The native-only option saves an explicit false in `BuffTimersNativeDB.blink`;
existing installations with no value retain the current blinking behavior.
This setting is account-wide alongside the replacement renderer's enabled flag.

Disabling blinking rebuilds the color curve with alpha 1 throughout. It keeps
the current timer colors and formatting, and resets icons, stack counts and
weapon enchant artwork to full opacity through the existing safe update path.
Re-enabling restores the warning waveform. The checkbox is disabled when the
renderer is off/unavailable or combat is active; the setter also rejects aura
restriction states. Other clients keep their original aura renderer unchanged.

The replay drives the actual options callbacks through default-on, disabling an
active short-buff warning, weapon enchants, unchanged long-buff yellow, blocked
combat changes, re-enabling and persistence across module initialization.
Native/options replays pass for Retail and Forever. Output is recorded in
`forever-native-replay-output.txt`; appearance still needs an in-game check.

Inspected `live` `297d7aaaa736` then `forever` `bebcb6bf309c`:
`Blizzard_CustomAuraButton.lua` (`SetDurationText` color binding) and
`LuaCurveObjectConstantsDocumentation.lua` (Step evaluation). All runtime/UI
changes are confined to the native-renderer code path and its localized option.

## Native curve point limit

The game reported that LuaColorCurveObject permits at most 256 points. The API
mirror describes AddPoint but omits this limit. The warning now uses 248 samples
at 8 Hz, with at most three additional threshold points (251 total). Its
1.5-second cycle, alpha range and RGB thresholds remain unchanged. Blinking off
still uses only three or four points.

The replay now enforces the 256-point limit on every AddPoint call, including all
profile/color combinations. That constraint reproduced the reported failure
before the runtime fix; Retail and Forever lifecycle replays pass afterward.

Inspected live 297d7aaaa736 and forever bebcb6bf309c sequentially:
Blizzard_APIDocumentationGenerated/LuaColorCurveObjectAPIDocumentation.lua
(AddPoint). The 256-point constraint comes from the user's actual client error,
not an assumption derived from those generated docs.

## Native color-check precision

The client subsequently reported `native timer color curve failed its checks`.
The old message did not include its sample or actual channel values, so it does
not establish which comparison failed. The check demanded 0.0001 accuracy on
all channels, including alpha 0.3, despite the API not documenting color-channel
round-trip precision. Byte-rounded evaluation reproduces that startup failure.

The check now permits one 8-bit channel step (1/255 plus a small float margin).
This accepts rounded alpha/color values while still rejecting an all-white
result for the expected long-buff yellow. A remaining failure includes the public
sample time and actual RGBA values; no protected aura data is logged. The mirror
does not contain the native curve evaluator, so byte quantization is a tested
compatibility case rather than a confirmed diagnosis of the user's engine.

Run the lifecycle replay with `BUFFTIMERS_TEST_COLOR_BYTES` false and true in
separate VMs for each interface. Both modes pass for 120105 and 16001, including
incorrect-color fallback, blinking on/off, colors and frame access restrictions.
Output is in `forever-native-replay-output.txt`. Real-client confirmation still
requires reload and re-enabling the replacement renderer if the prior failure
saved it as disabled.

Inspected `live` `297d7aaaa736` then `forever` `bebcb6bf309c`:
`LuaColorCurveObjectAPIDocumentation.lua` (`EvaluateUnpacked`, numeric channels)
and `Blizzard_SharedXMLBase/Color.lua` (float and byte color representations).

## BetterBlizzFrames compatibility

The installed BetterBlizzFrames v2.2.2c replaces player auras with its own native
containers and reparents Blizzard's original buttons to a hidden frame. BuffTimers
must adapt that display rather than create a second competing buff grid. The
installed `retail/modules/auras.lua` and `forever/modules/auras.lua` are identical
(SHA256 `931d923b44ecb8c65a4b19402ecf3eb5960508bcda773c6ada6a1a44cba6cedb`).
Those files were read without modifying BetterBlizzFrames or its saved settings.

When BBF exposes its native `auraHosts.playerBuffs`, BuffTimers binds its formatter
and color curve to BBF's timer FontStrings. BBF keeps the group filters, sorting,
layout, hidden-aura popup, Masque skins, tooltips and cancellation actions. Target,
focus and player debuff timers are not adapted. BuffTimers' font and position
settings apply when text customization is enabled; otherwise BBF retains those
styles. The existing replacement-renderer checkbox enables or disables this
integration automatically, without another option.

The adapter covers existing groups and wraps their initialization callbacks for
future frames, retaining BBF's callback and filter arguments. It enumerates native
frames only outside combat/aura restrictions. Native initialization callbacks run
before frame access restrictions are applied, so new buttons can adopt the last
compiled public configuration during combat. BBF restyles trigger reapplication,
and late BBF initialization disables any previously created standalone renderer.

Detailed hover uses the native cooldown countdown channel, preserving BBF's
existing optional cooldown swipe. Compact text visibility is controlled through
BBF's text-layer parent. Warning alpha and hover colors are forwarded to allowed
regions using secret-capable native setters. BBF's separate ordinary imbue cells
use their own DurationTextBinding; these also receive the formatter and curve.
They get an independent invisible clock so disabling BBF's cooldown swipes does
not disable their warnings or hover. Ordinary imbue cells can be refreshed in
combat without enumerating private aura frames.

Opt-out resets timer bindings, owned countdown channels, opacity and BBF's cached
duration-curve marker, then asks BBF to restore its own current styles. Inaccessible
regions defer restoration rather than receiving forbidden display calls. No
BetterBlizzFrames files, configuration values or group/filter settings are changed.

The BBF contract fixture is `Tests/bbf-native-replay.lua`, loaded by the existing
native replay with `BUFFTIMERS_TEST_BBF=true`; set `BUFFTIMERS_TEST_BBF_LATE=true`
to exercise late ownership. The fixture models the installed BBF source contract,
not its entire addon or WoW's taint engine. It covers grouped/filtered buffs,
Masque metadata, native and ordinary weapon enchants, BBF restyles, new native
buttons during secret auras, font/color changes, blinking off, detailed hover,
opt-out/restoration and re-enabling. The old runtime reproduced the competing
renderer failure with this fixture. Output is in `bbf-native-replay-output.txt`.

Run the fixture for interfaces 120105 and 16001, with early/late ownership and
`BUFFTIMERS_TEST_COLOR_BYTES` false/true in separate Lua VMs. All eight combinations
pass. The original native replay, style restoration replay, upstream duration
replay and Lua 5.1 parsing also pass. Real-client BBF layout, native countdown text
visibility, Masque appearance and combat security still need confirmation after
reload. Compare a long buff, refresh it in combat, hover it, check a shaman imbue,
and toggle the replacement renderer off/on to verify BBF's display is restored.

Inspected `live` `297d7aaaa736` then `forever` `bebcb6bf309c` sequentially:
`Blizzard_CustomAuraContainer.lua` (group enumeration and creation),
`Blizzard_AuraContainerFrameProviders.lua` (initialization before restrictions),
`Blizzard_CustomAuraButton.lua` (native text/cooldown bindings),
`FrameAPICooldownDocumentation.lua` (countdown formatter/FontString), and
`SimpleFontStringAPIDocumentation.lua` (secret-safe color forwarding).

## BBF hover anchor correction

The first in-game BBF integration attempt stopped with `FontString:SetPoint`
usage errors. Its hover setup copied `text:GetPoint(i)` directly into SetPoint.
Blizzard documents GetPoint as both MayReturnNothing and
SecretWhenAnchoringSecret, while SetPoint only accepts secret arguments from
untainted execution. An accessible text object does not guarantee its numeric
anchor values can be reused by addon code.

The hover timer now anchors its CENTER directly to the existing BBF timer's
CENTER with public zero offsets. This follows BBF/BuffTimers font positioning
without querying, copying, testing or normalizing native anchor values. The
exact invalid argument from the user's old message is not available, but this
removes that unsafe copy entirely.

The BBF fixture now rejects reads of its native timer anchors. The old runtime
reproduces the configuration failure with that constraint; the updated runtime
passes all Retail/Forever, early/late BBF and color-precision replay combinations.
Real-client placement still needs confirmation after reload.

Inspected `live` `297d7aaaa736` then `forever` `bebcb6bf309c`:
`SimpleScriptRegionResizingAPIDocumentation.lua` (GetPoint and SetPoint contracts).

## BlizzBuffsFacade fallback

BlizzBuffsFacade (Masque skinner for Blizzard buffs) hooks
`BuffFrame:UpdateAuraButtons`, `UpdateGridLayout` and `OnEditModeEnter` and adds
each entry of `BuffFrame.auraFrames` to its "Blizzard Buffs" Masque groups. The
replacement renderer hides exactly those original buttons with alpha 0 and draws
its own `CustomAuraContainerTemplate` buttons, which BlizzBuffsFacade never
skins, so every Masque skin disappeared (CurseForge comment 8729287).

While `C_AddOns.IsAddOnLoaded("BlizzBuffsFacade")` is true and BetterBlizzFrames
does not own the player buff host, native mode now reports why and uses the
existing renderer, the same way it handles gamepad navigation and collapsed buffs.
BetterBlizzFrames keeps priority because native mode styles BBF's own buttons
rather than hiding them. The replay checks fallback, message and resumption for
every Retail/Forever and color-precision combination; the BBF replay output is
unchanged. Combat timer formatting therefore follows the existing renderer while
BlizzBuffsFacade is enabled. In-game confirmation with Masque skins is still needed.

Inspected `live` `ab5cb850a3f6` then `forever` `3d8abb1da73a`:
`Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua` (`IsAddOnLoaded`),
`Blizzard_BuffFrame/BuffFrame.lua` (player buff order and `auraFrames`), and
`Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`.
