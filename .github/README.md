# BuffTimers

World of Warcraft addon to show accurate buff durations, with optional seconds and milliseconds.

## 🔤 Translation needed!

I need help translating this addon! If you notice your language is not supported and you would like to help, then you can take a look at [this file](https://github.com/sandervspl/BuffTimers/blob/master/Locales.lua#L17) and DM me the translation for the text in quotes. I will mention your name in the changelog if you want <3

The following languages have been translated by a robot. Please let me know if they are incorrect!

- French
- Italian
- Spanish
- Portuguese (Brazil)
- Chinese (traditional and simplified)
- Korean

### Credits

A thank you and shoutout to the people that helped me with translations for this addon!

- Russian: **Hubbotu**
- German: **ysjoelfir**

## Development

Unit tests use [Mechanic](https://github.com/Falkicon/Mechanic) v1.4.2 and Busted with Lua 5.1. Mechanic currently needs an editable checkout so its dashboard and command assets remain available:

```powershell
git clone --branch v1.4.2 --depth 1 https://github.com/Falkicon/Mechanic.git ..\Mechanic
python -m pip install --editable ..\Mechanic\desktop
$mechanicScripts = python -c "import sysconfig; print(sysconfig.get_path('scripts', scheme='nt_user'))"
$env:Path = "$mechanicScripts;$env:Path"
luarocks install busted
mech setup-busted
mech call addon.test '{\"addon\":\"BuffTimers\",\"path\":\".\"}'
```

The same suite can be run directly with `busted`.

### Client compatibility matrix

`addon.test` runs the compatibility cases in `Tests/client_compatibility_spec.lua` for every
interface declared by `BuffTimers.toc`:

- Retail (`120100`, upstream `live`)
- Mists of Pandaria Classic (`50504`, upstream `classic`)
- Titan (`38002`, upstream `classic_titan`)
- Anniversary (`20506`, upstream `classic_anniversary`)
- Classic Era (`11509`, upstream `classic_era`)

The fixtures mirror Blizzard's current normal buff, debuff, temporary-enchant, and deadly-debuff
button records. The matrix also fails if the interfaces in the TOC and tests drift apart.

Mechanic's offline tests do not launch or emulate a WoW client. After they pass, use
`addon.sync` to link BuffTimers into each installed client and perform an in-game smoke test.
Mechanic v1.4.2's `addon.validate` command has a hard-coded, older Retail interface list, so the
WoW UI source audit and the TOC matrix test are the compatibility authorities for these versions.
