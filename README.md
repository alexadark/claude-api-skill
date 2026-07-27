# claude-api

A replacement for the built-in `claude-api` skill in Claude Code.

The built-in one loads about 340,000 tokens when it triggers — reference docs for nine
languages plus a large shared folder, all at once. This one loads about 1,000, and reads a
single reference file when it actually needs one.

Same job: stop Claude stating a model ID, a price, or a limit from memory, because those
change every few months and stale values cause 404s and wrong cost estimates.

## Why the built-in loads everything

Its SKILL.md references every language doc inline, and anything referenced inline is loaded
on trigger. Its own text says to detect the project language and read only that folder, but
the detection never gets a chance to run.

## What this one does instead

- **Volatile facts are never stored.** No model IDs, no prices, no context windows written
  down. The skill forbids answering from memory and points at the live `/v1/models` endpoint
  and the pricing page.
- **Stable docs are indexed, not loaded.** A routing table maps "what I need" to one file to
  read. Streaming, prompt caching, tool use, error codes, SDK syntax.
- **What actually breaks stays inline.** The parameters that now return a 400, and the two
  defaults that fail silently instead of erroring.

Python, TypeScript and curl only. For Java, Go, Ruby, PHP or C#, it says so and sends you to
the SDK repo.

## Install

```bash
git clone https://github.com/alexadark/claude-api-skill ~/.claude/skills/claude-api
bash ~/.claude/skills/claude-api/scripts/resync.sh --force
```

A personal skill overrides a built-in one with the same name (precedence is
Enterprise > Personal > Project > Bundled), so the directory has to be called `claude-api`.
Nothing else to configure.

## The resync script

The reference docs are Anthropic's, so this repo does not ship them. `scripts/resync.sh`
copies them from the bundled skill already on your machine — Python, TypeScript, curl and
the shared folder, skipping the five languages this skill does not cover.

The bundled skill lives in a temp directory keyed to your Claude Code version, so it is wiped
on every update. Run the script again after an update, or wire it to a SessionStart hook in
`~/.claude/settings.json` and forget about it:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/skills/claude-api/scripts/resync.sh >/dev/null 2>&1 &"
          }
        ]
      }
    ]
  }
}
```

It compares the version stamp in `references/SOURCE.txt` against the current bundled copy and
does nothing when they match.

## If you just want the built-in gone

```json
{ "skillOverrides": { "claude-api": "off" } }
```

in `~/.claude/settings.json`. `"disableBundledSkills": true` turns off all bundled skills.

## Related

- [efficient-delegation](https://github.com/alexadark/efficient-delegation-skill) — this skill
  defers to it for splitting work between models when one is installed. Works fine without it.
- [garden-check](https://github.com/alexadark/garden-check-skill) — read-only audit of your
  Claude Code setup. Useful for finding the rest of what is quietly loading.
- [All my skills](https://github.com/alexadark/skills)
