---
name: claude-api
description: Build applications with the Anthropic API (Claude models) in Python, TypeScript, or curl. Covers model IDs, pricing, streaming, prompt caching, tool use, structured outputs, batches, files, and agent design. Use when writing or debugging code that calls Claude via the anthropic SDK, @anthropic-ai/sdk, or raw HTTP; when choosing a model or estimating cost; when migrating to a newer model; or when a request returns 400 / refusal / truncated output. Also triggers on "which model should I use", "how much will this cost", "claude api", "anthropic sdk", "prompt caching", "model id".
---

<objective>
Ship correct Anthropic API code without loading the whole reference library. Volatile facts (model IDs, prices, limits) are always verified live; stable mechanics are read on demand from `references/`.
</objective>

<critical>
NEVER state a model ID, price, context window, or output cap from memory. These change every few months and stale values cause 404s and wrong cost estimates.
Verify first, one of:
- `curl -s https://api.anthropic.com/v1/models -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01"` — the authoritative live list
- WebFetch `https://platform.claude.com/docs/en/about-claude/models/overview.md` (IDs, context, limits) or `https://platform.claude.com/docs/en/pricing.md` (prices)
- `references/shared/models.md` — snapshot only, treat as a hint, never as the answer

NEVER conclude a feature does not exist because `references/` omits it. The snapshot lags. Check live before saying no.
</critical>

<parameters_that_400>
Current-generation models reject parameters that older code carries. Strip these:
- `thinking: {type: "enabled", budget_tokens: N}` → use `{type: "adaptive"}` plus `output_config: {effort: ...}`
- `temperature`, `top_p`, `top_k` → removed; steer with the prompt instead
- Assistant-turn prefill (messages ending on `role: "assistant"`) → use `output_config.format` (structured outputs) or a system instruction
- `output_format` at top level → now `output_config: {format: ...}`

Two defaults that bite silently rather than erroring:
- `thinking.display` defaults to `omitted` → thinking blocks stream with empty text. Set `"summarized"` if reasoning is shown to users.
- Thinking is ON by default on the newest models. `max_tokens` caps thinking + text together, so a tightly sized `max_tokens` truncates. Raise it, or disable thinking (only valid at effort `high` or below).
</parameters_that_400>

<latency>
For interactive or streaming UX: `thinking: {type: "disabled"}`, `output_config: {effort: "low"}`, `stream: true`.
Non-streaming `max_tokens` above ~16k risks an SDK HTTP timeout. Above that, stream and use `.get_final_message()` / `.finalMessage()`.
</latency>

<routing>
Read ONE file, only when the task needs it. Do not preload.

| Need | Read |
|---|---|
| Python SDK: client, messages, thinking, caching, errors | `references/python/claude-api/README.md` |
| Python: streaming / tool use / batches / files | `references/python/claude-api/{streaming,tool-use,batches,files-api}.md` |
| TypeScript SDK: same split | `references/typescript/claude-api/{README,streaming,tool-use,batches,files-api}.md` |
| Raw HTTP / shell test | `references/curl/examples.md` |
| Cache design, breakpoints, why hit rate is zero | `references/shared/prompt-caching.md` |
| Tool-use concepts, tool runner vs manual loop, server tools | `references/shared/tool-use-concepts.md` |
| Agent design: tool surface, context management | `references/shared/agent-design.md` |
| 4xx/5xx meanings, typed SDK exceptions | `references/shared/error-codes.md` |
| Moving existing code to a newer model | `references/shared/model-migration.md` (large — jump to the target-model section) |
| Counting tokens in a file or prompt | `references/shared/token-counting.md` |
| Bedrock / Vertex / Foundry feature gaps | `references/shared/platform-availability.md` |
| Server-managed agents, sessions, environments | `references/shared/managed-agents-overview.md`, then the topical `managed-agents-*.md` |
| Live doc URLs for anything missing | `references/shared/live-sources.md` |
</routing>

<boundaries>
Python, TypeScript, and curl only. For Java, Go, Ruby, PHP, or C#, say the reference is not mirrored here and fetch the SDK repo from `references/shared/live-sources.md`.
NEVER produce OpenAI-SDK or OpenAI-compatible shim code. If the target file already uses another provider, stop and ask before rewriting it.
Auth: an unset `ANTHROPIC_API_KEY` does not mean no credentials. Run `ant auth status` before asking the user for a key.
</boundaries>

<delegation>
When a task means reading several reference files or sweeping many call sites (a model migration across a repo, an audit of every `messages.create`), delegate the reading and the mechanical edits to cheaper sub-agents, one self-contained slice each. Keep at the top model: model choice, cost tradeoffs, architecture, and the final review of any code that ships. Sub-agent findings are leads — re-verify a cited model ID or price against the live source before acting on it.
If an `efficient-delegation` skill is installed, follow it for the split.
</delegation>

<maintenance>
`references/` mirrors the bundled skill, minus the five unused languages. `references/SOURCE.txt` records the Claude Code version it came from.
`scripts/resync.sh` refreshes it and is wired to a SessionStart hook, so it self-heals after a Claude Code update. It is a no-op when already current; `--force` re-copies.
If `SOURCE.txt` is more than one Claude Code minor version behind and the hook has not fired, run `bash scripts/resync.sh --force`.
</maintenance>

<success_criteria>
- No model ID, price, or limit asserted without a live check
- At most one or two reference files read per task
- Working code in the project's own language and SDK, never a provider shim
</success_criteria>
