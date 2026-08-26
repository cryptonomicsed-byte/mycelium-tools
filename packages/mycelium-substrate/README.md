# mycelium-substrate

The stigmergic trace substrate: agents emit traces (via MCP or CLI), offline
miners find recurring patterns, findings can be applied as generated skills,
and results anchor to Gitea/Nostr/Vantage. Runs anywhere — VPS, desktop, or
a Termux phone — with zero required config (sane local-file defaults) and
full override via environment variables.

See the [mycelium-tools README](../../README.md) for install and
multi-device setup instructions. Full design writeup:
[cryptonomicsed-byte/mycelium](https://github.com/cryptonomicsed-byte/mycelium).

## Config (all optional, all have working local defaults)

| Var | Default | Purpose |
|---|---|---|
| `MYCELIUM_DB` | `~/mycelium/mycelium.db` | SQLite trace/finding store |
| `MYCELIUM_BACKEND` | `sqlite` | set `postgres` + `MYCELIUM_POSTGRES_URL` to use Postgres instead |
| `MYCELIUM_ADDR` | `localhost:8811` | HTTP gateway address (shared with the Go gateway, if run) |
| `MYCELIUM_SKILLS_DIR` / `MYCELIUM_ALERTS_DIR` / `MYCELIUM_FIXES_DIR` | `~/mycelium/generated-*` | where `apply_finding` writes generated artifacts |
| `MYCELIUM_CHECKPOINT_DIR` | `~/mycelium/checkpoints` | local anchor checkpoint |
| `GITEA_URL` / `GITEA_TOKEN` / `GITEA_REPO` / `GITEA_BRANCH` | unset | optional Gitea push on `mycelium publish` |
| `NOSTR_SECKEY` / `NOSTR_RELAY` | unset | optional Nostr publish of findings |
| `VANTAGE_URL` / `VANTAGE_KEY` | `https://omokoda.duckdns.org` | A2A findings publish target (`mycelium a2a`) |

## CLI

```
mycelium init                          # create substrate DB
mycelium trace --agent A --session S --kind tool_call --action patch
mycelium list [--agent A] [--limit N]
mycelium mine [--miner NAME|all]
mycelium findings [--state open]
mycelium apply FINDING_ID
mycelium cycle                         # mine (sandboxed) + auto-apply, cron-safe
mycelium publish                       # checkpoint + optional Gitea anchor
mycelium a2a [--limit N]               # publish open findings to Vantage feed
```

`mycelium-mcp` runs the same substrate as an MCP stdio server for any
MCP-aware agent (Claude Code, Codex, Hermes, ...).
