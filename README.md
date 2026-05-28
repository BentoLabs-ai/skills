# BentoLabs skills

[![skills.sh](https://skills.sh/b/BentoLabs-ai/skills)](https://skills.sh/BentoLabs-ai/skills)

Agent Skills for [Bento](https://docs.bentolabs.ai). Skills are packaged instructions that teach AI coding agents how to use a product, library, or service.

Follows the [Agent Skills](https://agentskills.io/) format.

## Install

Install both skills:

```bash
npx skills add BentoLabs-ai/skills
```

Install one:

```bash
npx skills add BentoLabs-ai/skills --skill bentolabs-integrate
npx skills add BentoLabs-ai/skills --skill bentolabs-cli
```

## Available skills

### bentolabs-integrate

Integrate Bento into a Python app. Wire up `bento.instrument()` for Google ADK, manually track LLM calls with `bento.track_ai`, register identity getters at `bento.init`, group multi-step agent flows with `bento.begin` trajectories, and map OpenTelemetry GenAI / OpenInference attributes to Bento dashboard columns.

**Use when:**

- Setting up Bento in a new app
- Adding tracing to an existing Python codebase
- Debugging missing traces or empty dashboard columns
- Migrating from Raindrop or Langfuse

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
