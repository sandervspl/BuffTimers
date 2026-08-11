# BuffTimers agent instructions

## WoW UI source reference (mandatory)

For every task that diagnoses, reviews, or changes WoW addon behavior, Lua, XML, or TOC compatibility, consult [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source) before reaching a conclusion or editing code. Do not rely on memory when the reference can answer the question.

1. Determine the affected clients from the task and the supported interface versions in `BuffTimers.toc`. Treat changes to shared runtime files (`BuffTimers.lua`, `Options.lua`, `Locales.lua`, and `embeds.xml`) as cross-client unless the code path or task is explicitly client-specific. Use only `live` for confirmed Retail-only work. Available upstream branches can be listed with `git -C .cache/wow-ui-source branch -r`.
2. Inspect affected branches sequentially because the helper maintains one working checkout: run `scripts/sync-wow-ui-source.sh <branch>`, inspect that branch, and record its commit and relevant files before switching to the next branch.
3. Search `.cache/wow-ui-source/Interface/AddOns` for the Blizzard implementation and generated API documentation relevant to the task. Prefer `rg` for searches.
4. Treat the checkout as read-only. Never edit or commit files below `.cache/wow-ui-source`.
5. In the final response, name every branch and short commit inspected plus the main upstream file(s) or API definitions consulted. This evidence is required for code changes and behavior claims.

If the reference cannot be fetched or does not contain the relevant implementation, state that explicitly. Do not silently substitute recollection or unrelated third-party documentation.

The reference is not required for work that cannot affect addon behavior, such as repository-only documentation, release workflow, or metadata maintenance.
