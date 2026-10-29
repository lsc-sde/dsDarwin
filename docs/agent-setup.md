# Agent setup

This is the document which shows for the developers and other contributers how to extend the agentic development for this project. 

## MCP servers

Configured in [.mcp.json](../.mcp.json) (Claude Code) and [opencode.json](../opencode.json) (opencode).
Keep the two files in sync when you add or change a server.

| Server | What it gives the agent | Install on your machine |
|---|---|---|
| `datashield` | Talks to a DataSHIELD server ([obiba/datashield-mcp](https://github.com/obiba/datashield-mcp)) | [uv](https://docs.astral.sh/uv/) (`brew install uv`) |
| `r-mcptools` | R docs, package check/test/document, CRAN lookup ([mcptools](https://posit-dev.github.io/mcptools/), [btw](https://posit-dev.github.io/btw/)) | R, then `install.packages(c("mcptools", "btw"))` |
| `github` | Issues, PRs and repo access through GitHub's hosted server | [gh](https://cli.github.com/), then `gh auth login` |
| `context7` | Current library docs | Nothing |

The `github` server uses your `gh` login token; nothing is stored in the repo.
Claude Code fetches the token itself.
opencode reads it from `GITHUB_TOKEN`, so add `export GITHUB_TOKEN=$(gh auth token)` to your shell profile.

Check (Claude Code): `claude mcp list` should show each server as `Connected`.

## Skills

Repo skills live in [.agents/skills/](../.agents/skills/); `.claude/skills` is a symlink to it.
Nothing to install.

## Planning agent functions

[Superpowers](https://github.com/obra/superpowers) drives the brainstorm → plan → TDD workflow; its designs and plans go in [spec/iteration-plans/](../spec/iteration-plans/) (naming in [spec/README.md](../spec/README.md)).
Install it per agent:

| Agent | Install |
|---|---|
| Claude Code | `/plugin install superpowers@claude-plugins-official` |
| opencode | Tell opencode: `Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md` |
| GitHub Copilot CLI | `copilot plugin marketplace add obra/superpowers-marketplace`, then `copilot plugin install superpowers@superpowers-marketplace` |
| Other agents | See the [superpowers install guide](https://github.com/obra/superpowers#installation) |

Recommended: [grill-me](https://github.com/mattpocock/skills) makes the agent interview you, round by round, until a plan or design has no open questions.
Install it for your user, not the repo (`grill-me` calls `grilling`, so install both):

```sh
npx skills add https://github.com/mattpocock/skills --skill grill-me --skill grilling -g
```

Then type `/grill-me`; it never runs on its own.

## Caveman

[Caveman](https://github.com/JuliusBrussee/caveman) compresses what the agent reads (tool output, context) to save tokens.
It installs per user, not per repo, so it is not in `.mcp.json`.

Run `npx @caveman-ai/cli@latest` (needs Node.js 22.13+).
It finds the agents on your machine, shows what it will change, and sets them up; for Claude Code that includes a `caveman` MCP server.
`caveman setup` reopens that screen later.

Check (Claude Code): `claude mcp list` should show `caveman` as `Connected`.
