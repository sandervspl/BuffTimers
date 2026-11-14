# Secret aura timer formatting: Forever and Retail

Research performed 2026-11-14. Scope: Forever 1.60.1 / interface 16001 (`camelot`) and Retail Midnight 12.1.5 / interface 120105. Documentation only; no runtime changes or in-game execution.

## Findings that matter for BuffTimers

**A native custom formatter is supported in both inspected clients.** Keeping a 105-minute combat timer in minutes is a plausible supported presentation change, rather than a requirement to reveal secret seconds to addon Lua. The strongest route is a configured `SecondsFormatter` installed on a native `Cooldown` countdown or passed to a custom aura button's `SetDurationText`. A standalone `DurationTextBinding` can update an addon FontString, provided the addon has a permitted duration object to bind. The existence of these APIs does not establish that BuffTimers' existing Blizzard buff-frame hook can obtain that duration object in combat.

**Do not directly call `SecondsFormatter:Format(secretSeconds)` or `NumericFormatter:FormatNumber(secretSeconds)` from tainted addon execution.** Both are explicitly `SecretArguments = "AllowedWhenUntainted"` in the inspected Forever docs. `DurationObject:FormatRemainingDuration` has the same restriction: switching to that method is not an established workaround. Configuring an engine formatter using ordinary profile values and handing it to an engine-owned countdown/binding avoids that particular direct formatting call. Sources: [numeric formatter][F-numeric], [seconds formatter][F-seconds], [duration object][F-duration], [binding][F-binding], [cooldown][F-cooldown].

The supplied symptom (105m outside combat, 2h in combat) is consistent with different formatting paths. It does not prove a saved-profile error. Blizzard's default aura-container formatter explicitly permits hours once remaining seconds exceed 5400, uses one unit, and rounds the last displayed unit upward; 6300 seconds is therefore consistent with 2h. BuffTimers' own secret fallback may also account for the observed result. Identify the actual frame and writer before changing it. This is an inference from [Blizzard's default formatter configuration][F-shared], not an in-game reproduction.

## Exact source snapshots and availability

Fetched GitHub tree metadata and raw files at immutable commits, sequentially for Forever then live. Did not run the shared sync helper, switch a checkout, or read/write `.cache/wow-ui-source`. This respects the parent's exclusive use of that checkout.

| Branch | Commit | Upstream build | Verified source availability |
| --- | --- | --- | --- |
| `forever` | `bebcb6bf309cf41b41bd74f8ca651e6a105b2676` | 1.60.1 (70938) | DurationTextBinding, SecondsFormatter, custom aura containers/buttons, SetCountdownFormatter |
| `live` | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | 12.1.5 (70783) | Same APIs; independently inspected rather than inferred from Forever |

Commit metadata: [Forever snapshot][F-commit], [Retail snapshot][R-commit]. `DurationTextBindingObjectAPIDocumentation.lua`, `SecondsFormatterAPIDocumentation.lua`, `Blizzard_CustomAuraButton.lua`, and `Blizzard_AuraContainerShared.lua` were byte-identical across these two snapshots. Cooldown documentation differs elsewhere, but both list the relevant formatter/countdown APIs. Retail references: [binding][R-binding], [seconds][R-seconds], [cooldown][R-cooldown], [custom button][R-button].

These are source-verified build contracts, not a claim that every user's installation or older Midnight build provides them. Check `GetBuildInfo()` and feature-detect factories/methods. Do not classify Forever as ordinary Classic solely because its interface number is smaller. No conclusions were drawn for `classic`, `classic_titan`, `classic_anniversary`, or `classic_era`; this task does not change shared runtime code.

## 1. SecondsFormatter: minutes instead of hours

Verified controls in [SecondsFormatter API docs][F-seconds] and [enums][F-seconds-shared]:

- `SetMaxInterval(Enum.SecondsFormatterInterval.Minutes)` caps the largest interval at minutes. `SetMinInterval(Seconds)` allows short timers to show seconds; setting both bounds to Minutes expresses literal minutes-only formatting.
- `SetDesiredUnitCount(1)` requests a single unit. `SetCanRoundUpLastUnit(true)` controls upward rounding of the final unit.
- `SetCanRoundUpIntervals(false)` disables promotion such as 60m to 1h. Use alongside the maximum interval cap; do not depend on this flag alone to suppress ordinary hour-band selection.
- `SetDefaultAbbreviation(OneLetter)` supplies localized compact unit labels. `SetStripIntervalWhitespace(Strip)` is locale-aware; deDE and ruRU may preserve spaces. `StripIgnoreLocale` explicitly overrides locale behavior.
- `SetMillisecondsThreshold(5)` requests one decimal place below five seconds, not three-digit milliseconds. A saved `milliseconds=true` option can map to this threshold for the addon's existing under-five-seconds behavior, subject to in-client boundary verification.
- `SetRounding(Truncate)` controls fractional seconds separately from the round-last-unit setting. Verify exact boundaries rather than assuming these flags reproduce every legacy custom format.
- Curves can select min/max interval or desired unit count internally based on remaining seconds. This is preferable to addon comparisons against secret times.

**Proposed configuration, not executed in a client:**

```lua
local f = C_StringUtil.CreateSecondsFormatter()
f:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
f:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
f:SetMaxInterval(Enum.SecondsFormatterInterval.Minutes)
f:SetDesiredUnitCount(1)
f:SetCanRoundUpIntervals(false)
f:SetCanRoundUpLastUnit(true)
f:SetRounding(Enum.SecondsFormatterRounding.Truncate)
f:SetMillisecondsThreshold(5) -- profile-enabled tenths below five seconds
```

Expected intent: 6300 seconds stays in minutes, sub-minute values use seconds, and the last five seconds use tenths. Exact output at rounding boundaries remains unverified. This snippet deliberately does not call `f:Format` with a secret argument.

## 2. Native cooldown countdown

[Cooldown API documentation][F-cooldown] verifies:

- `Cooldown:SetCountdownFormatter(formatter)` accepts a native `NumericFormatter` object or nil. A `SecondsFormatter` implements that formatter contract. A Lua formatting callback is not accepted.
- `SetCooldownFromDurationObject(duration, clearIfZero)` supports a duration object, with `IsProtectedFunction = true` and `SecretArguments = "AllowedWhenUntainted"`; do not assume every protected/secret cooldown can be reconfigured by tainted code in combat.
- `SetCountdownMillisecondsThreshold(seconds)` supports native tenths. When a custom formatter is installed, configure its own milliseconds threshold too; the docs alone do not establish precedence between these settings.
- `SetCountdownAbbrevThreshold(seconds)` selects the unitless abbreviated `1:31` presentation below a threshold. Values above one hour or below one minute disable abbreviation. It is not a general maximum-unit setting and cannot express long-duration 105m by setting an enormous threshold.
- `SetHideCountdownNumbers` and `SetMinimumCountdownDuration` are separate visibility controls. Styling a formatter does not ensure its text is visible.

Actual addon implementation: [tullaCTC themer.lua at a20c99c2eab0](https://github.com/tullamods/tullaCTC/blob/a20c99c2eab0305613c7f3e85acf332bd264301f/tullaCTC/themer.lua#L326) installs an engine formatter on the cooldown. This establishes practical usage, not proof that BuffTimers' current aura text is a Cooldown countdown.

## 3. Standalone DurationTextBinding

[DurationUtil][F-util] creates a binding. [Binding API docs][F-binding] verify `SetFontString`, `SetDuration`, `SetFormatter`, `SetEnabled`, `SetUpdateInterval`, `SetExpiredText`, `SetZeroDurationText`, and `UpdateFontString`. Automatic updates happen inside the binding; zero update interval means every game tick. `SetTextFormat` can substitute duration-property components through supplied NumericFormatters. `GetFormattedText` is explicitly conditionally secret, so it is not a way to recover readable text for addon parsing.

**Proposed standalone use:** configure the formatter above, bind an ordinary FontString, bind a legitimate `DurationObject`, set blank zero/expired text, and enable automatic updates. Keep ownership of the binding, disable/reassign it when a pooled aura changes, and prevent an older OnUpdate/text writer from immediately overwriting its output. These lifecycle requirements are implementation proposals, not a tested BuffTimers patch.

Important access limitation: [C_UnitAuras.GetAuraDuration][F-unit] carries `RequiresUnitAuraAccess = true` and `RequiresValidUnitAuraInstance = true` as well as the secret argument restriction. Its existence is not proof that an addon can fetch arbitrary combat aura durations on current Midnight/Forever. Binding factory arguments use ordinary configuration, but duration acquisition still needs a supported access path. Likewise, direct duration formatting methods remain restricted; use a binding/countdown consumer rather than claiming `FormatRemainingDuration` bypasses taint.

## 4. Aura containers: strongest verified secret-aura presentation route

[CustomAuraButtonSharedMixin:SetDurationText][F-button] accepts a FontString and options containing `binding`, `textFormatter`, `textFormat`, and `textColor` (see the [option processor API][F-options]). Source behavior:

1. Processes a secure copy of the options and validates/adopts the FontString.
2. Adds secret aspects for Text, Alpha, and VertexColor.
3. Copies the supplied binding with `Assign`, or resets to defaults and installs Blizzard's default formatter.
4. Assigns its own aura duration object and the supplied FontString.
5. Applies `textFormat` in preference to `textFormatter`; a supplied binding alone does not supersede a later explicit text-format option.
6. `ApplyDurationText` binds the current duration and enables updates when the duration is nonzero. `ClearDurationText` disables the binding.

Thus the supported configuration is `button:SetDurationText(fs, { textFormatter = f })` during permitted initialization/configuration, not subclassing Blizzard's private aura update methods and manually reading their aura values. Changing the original binding after registration should not be assumed to update the button, because it copies the supplied binding. Similarly, do not assume mutating a formatter after registration updates every consumer without checking copy behavior in-client.

[AuraButtonPrivateMixin:UpdateAuraDuration][F-aura-button] explains why Blizzard manually maintains the duration object: private auras do not support the UnitAura duration API, temporary enchants are fake auras, and the duration object's identity must stay stable to avoid leaking aura reassignment. This is direct upstream evidence against treating private `auraDuration` fields as an addon-readable discovery API.

[Inbound object initialization][F-inbound] prevents removing secret aspects and changing adopted objects' parents. The aura container owns managed frame lifecycle/layout. Preserve these constraints rather than assuming an existing arbitrary buff FontString can be freely transplanted into a container. A migration to containers may be necessary for access, but would be a larger runtime change than a formatter-only change.

Blizzard's default [aura formatter][F-shared] uses a stepped maximum-interval curve at 91 seconds, 5401 seconds, and 129601 seconds; one-letter abbreviations; truncated fractional seconds; upward rounding of the last unit; and one desired unit. This deliberately differs from a strict always-minutes profile. Supply a custom formatter rather than modifying Blizzard's shared default object.

## Primary developer discussions and real-world caveats

- [Blizzard: Combat Philosophy and Addon Disarmament in Midnight](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight) is a directly retrieved first-party announcement. It separates displaying combat information from addon processing and explains why raw-data rebuilds can break while cosmetic customization remains intended. It does not promise any particular timer formatting API.
- [EllesmereUI PR #1015](https://github.com/EllesmereGaming/EllesmereUI/pull/1015) documents a real `SetCountdownFormatter` argument error caused by passing a Lua closure. Its change uses cached engine formatter objects. This corroborates the generated type contract; it does not mean NumericRuleFormatter is the only accepted subtype.
- [BetterFramesForever / BetterPlatesForever PR #65](https://github.com/Tgaarden/Gaar.WowAddons/pull/65) uses `SetDurationText(..., { textFormatter, textColor })` on client-drawn combat aura icons and `SetCountdownFormatter` on fallback icons, with native numeric-rule formatting. The author explicitly lists in-game checks still needed. Treat it as a concrete Forever implementation example, not confirmed live correctness.
- [tullaCTC discussion #14](https://github.com/tullamods/tullaCTC/issues/14), including [Tuller's response](https://github.com/tullamods/tullaCTC/issues/14#issuecomment-3831800081), discusses aura-versus-cooldown rounding, native aura display time, and attempts at conditional tenths/scale. Its early assertions that there is no duration formatter predate newer APIs and are superseded by the inspected source. Do not copy the old workarounds as present-day restrictions.
- [EllesmereUI issue #1433](https://github.com/EllesmereGaming/EllesmereUI/issues/1433) reports a native divide-by-zero crash in Retail 12.1.0 build 69299 around aura duration text / `binding:SetDuration`. The reporter does not isolate whether the formatter, interval, binding, or client is responsible; there were no comments establishing a cause/fix when checked. This is an unresolved historical client report, not proof that bindings universally crash or that Forever is affected. A Lua `pcall` cannot be assumed to catch a native crash.
- [AuraMaster style implementation at 92749c914879](https://github.com/tusharsaxena/AuraMaster/blob/92749c914879ac3cfbf11a5c531d4c58e42da252/modules/Style.lua#L808) binds duration text via engine options; it caches formatter objects. [Its Text-style issue #2](https://github.com/tusharsaxena/AuraMaster/issues/2) explicitly proposes engine-bound text for secret combat auras. The issue's acceptance criteria are requirements, not test results.

## Announcement provenance and remaining gaps

Search located Blizzard UI-team announcements originally distributed on the WoW UI Discord, but I could not directly retrieve the original Discord messages. Do not present a third-party transcription as independently inspected first-party discussion.

- A [Wowhead transcription of Blizzard's Forever statement](https://www.wowhead.com/news/wow-forever-will-have-addon-changes-from-midnight-382921), published September 16, says Forever shares the Mainline UI code family, secrets, and the 12.1.0 aura-container changes. The original Discord message was not independently inspected. The two exact source snapshots above independently establish the relevant APIs in Forever and Retail; the report does not rely on that transcription to infer availability.
- [12.0.7 API notes transcription](https://warcraft.wiki.gg/wiki/Patch_12.0.7/API_changes/notes) dates the DurationTextBinding announcement to the May 28 RC update and provides the Blizzard binding example. [12.1.0 API notes transcription](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes/notes) describes combat aura access restrictions, managed containers, and aura-button changes. These are discovery leads only: full-page/API fetching returned HTTP 403, search returned excerpts, and the original Discord posts were not inspected. Use checked source for present API claims. Generic statements in older Classic notes that secrets are disabled must not be applied to Forever.
- No client session was available to verify 6300-second output, formatter copying, exact fractional boundary behavior, profile toggles during combat, or whether BuffTimers can attach a binding to its present Blizzard buff-frame hook. Those are the parent's implementation/validation questions.

## Suggested verification for the parent

Use a long buff with roughly 105 minutes remaining and a short aura together. Record build, loaded addon version, selected profile and formatter path. Capture outside combat, combat entry, refresh during combat, expiry, leaving combat, and reload. Repeat with milliseconds true/false and with minutes versus hour profiles. Include a timer crossing 60 minutes, 60 seconds, and 5 seconds; test aura recycling and temporary weapon enchants. Save a repeatable in-game command sequence plus screenshots/error log. Native formatter output on a plain synthetic duration is useful preliminary validation, but does not establish access or taint safety for real combat auras.

## Immutable upstream source links

[F-commit]: https://github.com/Gethe/wow-ui-source/commit/bebcb6bf309cf41b41bd74f8ca651e6a105b2676
[R-commit]: https://github.com/Gethe/wow-ui-source/commit/297d7aaaa736f346b3e036f38ee088eaf7f8c07f
[F-numeric]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/NumericFormatterAPIDocumentation.lua
[F-seconds]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecondsFormatterAPIDocumentation.lua
[F-seconds-shared]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecondsFormatterSharedDocumentation.lua
[F-duration]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/LuaDurationObjectAPIDocumentation.lua
[F-binding]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/DurationTextBindingObjectAPIDocumentation.lua
[F-util]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/DurationUtilDocumentation.lua
[F-cooldown]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICooldownDocumentation.lua
[F-unit]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua
[F-options]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuraContainerUtilDocumentation.lua
[F-button]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua#L178
[F-aura-button]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraButton.lua#L167
[F-shared]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerShared.lua#L72
[F-inbound]: https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua#L361
[R-binding]: https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/DurationTextBindingObjectAPIDocumentation.lua
[R-seconds]: https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecondsFormatterAPIDocumentation.lua
[R-cooldown]: https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICooldownDocumentation.lua
[R-button]: https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua
