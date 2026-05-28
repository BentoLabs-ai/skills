# BentoLabs skills

[![skills.sh](https://skills.sh/b/BentoLabs-ai/skills)](https://skills.sh/BentoLabs-ai/skills)

Agent Skills for [Bento](https://docs.bentolabs.ai). Skills are packaged instructions that teach AI coding agents how to use a product, library, or service.

Follows the [Agent Skills](https://agentskills.io/) format.

## Install

Install all three:

```bash
npx skills add BentoLabs-ai/skills
```

Install one:

```bash
npx skills add BentoLabs-ai/skills --skill bentolabs-integrate
npx skills add BentoLabs-ai/skills --skill bentolabs-migrate
npx skills add BentoLabs-ai/skills --skill bentolabs-cli
```

## Available skills

### bentolabs-integrate

Greenfield integration of Bento into a new app. Three paths in order of preference: direct export (point an agent SDK's own OpenTelemetry / OpenInference exporter at Bento — no Bento SDK, any language), the one-line Google ADK auto-instrument (`bentolabs-sdk[adk]` + `bento.instrument()`), and manual `bento.track_ai` per LLM call. Also registers identity getters at `bento.init`, groups multi-step flows with `bento.begin`, and maps GenAI / OpenInference attributes to dashboard columns.

**Use when:**

- Setting up Bento in a new app with no existing observability SDK
- Pointing a LangChain / Pydantic AI / Mastra / Vercel AI SDK app at Bento
- Debugging missing traces or empty dashboard columns
- Choosing between direct export, the ADK auto-instrument, and manual `track_ai`

### bentolabs-migrate

Move an existing observability or agent stack to Bento. Covers three paths in priority order — direct OTLP export (repoint an agent SDK's own exporter at Bento, no Bento SDK), OpenInference instrumentors wired to a `BentoLabsSpanProcessor`, and manual per-call translation — plus the source-specific guides for Raindrop and Langfuse.

**Use when:**

- Replacing Raindrop or Langfuse with Bento
- Sending Mastra / LangChain / Pydantic AI / Vercel AI SDK traces to Bento by repointing its exporter
- Converting `@observe`, `raindrop.track_ai`, `langfuse.openai`, or `langfuse.langchain` to Bento equivalents
- Setting up OpenInference instrumentors against a `BentoLabsSpanProcessor`

### bentolabs-cli

Drive the Bento platform from your terminal. List traces and signals, script analytics into `jq` pipelines, automate workflows in CI, and hit any Bento REST endpoint with `bentolabs raw`.

**Use when:**

- Listing traces, signals, or analytics from a terminal
- Scripting Bento data into pipelines
- Hitting an ad-hoc Bento API endpoint
- Automating Bento workflows in CI
- Bootstrapping the CLI on a new machine

## Repo layout

```
skills/
├── bentolabs-integrate/
│   ├── SKILL.md         # narrative + decision flow, < 500 lines
│   ├── scripts/         # bash + Python the agent runs
│   └── references/      # deep reference loaded on demand
├── bentolabs-migrate/
│   ├── SKILL.md
│   ├── scripts/
│   └── references/
└── bentolabs-cli/
    ├── SKILL.md
    ├── scripts/
    └── references/
skills.sh.json           # skills.sh directory page grouping
```

Each skill follows the [agentskills.io directory convention](https://agentskills.io/specification#directory-structure): `SKILL.md` for instructions, `scripts/` for executable code, `references/` for documentation the agent loads on demand. Edit any file in place.

The frontmatter `description` is the only signal an agent uses to decide whether to load the skill into context. Keep it accurate and trigger-rich.

## Related

- Bento docs: [docs.bentolabs.ai](https://docs.bentolabs.ai)
- Agent Skills spec: [agentskills.io](https://agentskills.io)
- Skills CLI: [github.com/vercel-labs/skills](https://github.com/vercel-labs/skills)
