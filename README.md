# bentolabs skill

The Agent Skill that teaches Claude how to integrate [Bento](https://docs.bentolabs.ai) into a Python app.

## Install

```bash
npx skills add BentoLabs-ai/skills
```

This fetches `SKILL.md` from this repo and registers it with your local Claude Code (or any Agent Skills compatible client).

## What it covers

Wiring `bento.instrument()` for Google ADK, manual tracking with `bento.track_ai`, identity getters at `bento.init`, multi-step trajectories with `bento.begin`, OpenTelemetry GenAI / OpenInference attribute mapping, debugging missing traces, and migrating from Raindrop or Langfuse.

## Editing

`SKILL.md` is the only published file. Keep the frontmatter `description` accurate and full of trigger phrases. It is the only signal Claude uses to decide whether to load the skill into context.

Run the validator locally before pushing:

```bash
node .github/scripts/validate-skill.mjs SKILL.md
```

CI runs the same check on every PR.

## Related

- Bento docs: [docs.bentolabs.ai](https://docs.bentolabs.ai)
- Agent Skills spec: [github.com/anthropics/skills](https://github.com/anthropics/skills)
