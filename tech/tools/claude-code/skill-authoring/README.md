# Skill Authoring

Specification and style conventions for authoring Claude Code and Codex skills. Covers SKILL.md
structure, frontmatter fields, progressive disclosure, and reference file organization.

- `skill-spec.md` — official frontmatter fields, substitutions, token budgets (pinned from docs).
- `skill-style.md` — dotfiles house body style, description pattern, templates, staging discipline.
- `skill-script-extraction.md` — when to move deterministic shell out of a `SKILL.md` body into a
  versioned `agent-helper` subcommand, the skill-as-orchestrator model, and the `msg` output/status
  contract.
