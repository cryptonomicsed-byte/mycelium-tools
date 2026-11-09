# mycelium-tools

Five installable, config-driven tools that used to be Fold4-phone-only
scripts hardcoded to one device's paths. Now: `pip install`, set a few
environment variables, run — on a VPS, a desktop, or a Termux phone.
**The Fold4 is just the first device running these, not a requirement for
running them.**

Part of the ares/omokoda/vantage ecosystem orchestration
(`~/ares_orchestration_master.md`, project P5 MYCELIUM). Every daemon
belongs to a named project and lives in its own repo — this one owns the
universal substrate tools; `ares-control` (a separate repo) just registers
and toggles them, it does not contain their code.

## The five tools

| Tool | Package | What it does |
|---|---|---|
| **U1** `mycelium`, `mycelium-mcp`, `mycelium-http` | `mycelium-substrate` | The trace substrate: durable SQLite/Postgres event log, offline pattern miners, MCP stdio server for any MCP-aware agent, and a minimal stdlib HTTP server (trace ingest/query only — not the full dashboard, see below) |
| **U2** `mycelium-collector` | `mycelium-collector` | Wallet-intel collector — GMGN smart-money/KOL trades, optional real Helius API pull, GeckoTerminal price enrichment — emits traces into a substrate, local or remote |
| **U3** `mycelium-cycle` | `mycelium-cycle` | Chains one self-maintenance cycle: mine + auto-apply → publish (anchor) → A2A-publish findings to Vantage. Cron/timer-safe |
| **U4** `substrate-tunnel` | `substrate-tunnel` | Generic autossh-managed reverse-SSH tunnel — join any device to a shared substrate host with one command |
| **U5** `picks-digest` | `picks-client` | Fetches a picks digest from any `GET /api/picks`-shaped service |

All five are independent pip packages under `packages/`, each with its own
`pyproject.toml` and README with the full env-var reference.

## Install

```bash
git clone https://github.com/cryptonomicsed-byte/mycelium-tools.git
cd mycelium-tools
./install.sh                       # installs into ~/.venvs/mycelium-tools
# or: ./install.sh /custom/venv/path
```

No root required, ever. `install.sh` creates a virtualenv, installs all
five packages into it, and optionally offers to copy the systemd
`--user` unit templates from `systemd/` into `~/.config/systemd/user/`.

## Quickstart: run a substrate + collector on one device

```bash
source ~/.venvs/mycelium-tools/bin/activate
mycelium init                      # create the local trace DB
mycelium-http &                    # substrate HTTP server on :8811
mycelium-collector --once          # one collection cycle
mycelium findings                  # see what the miners found
```

## How to add your own device

This is the point of the project — it's designed to work for a stranger on
their own VPS/phone/laptop, not just the original operator. Three ways to
participate, pick what fits:

### 1. Run your own standalone substrate
No relay, no tunnel — just your own local mining/tracing loop:
```bash
./install.sh
source ~/.venvs/mycelium-tools/bin/activate
mycelium init
mycelium-http &
mycelium-cycle          # run manually, or install the .timer unit (below) for cron-free scheduling
```

### 2. Join a shared substrate (recommended for a fleet)
Point your tools at someone else's already-running substrate instead of
hosting your own — nothing to keep alive locally except the tunnel:
```bash
export SUBSTRATE_RELAY_HOST=their.relay.ip
export SUBSTRATE_RELAY_USER=youruser
export SUBSTRATE_SSH_KEY=~/.ssh/id_ed25519
substrate-tunnel &
export MYCELIUM_URL=http://127.0.0.1:8811   # tunneled to the relay's :8811
mycelium-collector --once
```
The relay operator needs to add your SSH public key and allow
`GatewayPorts` / `AllowTcpForwarding` for reverse tunnels in their sshd
config — that's the one manual step on their side, everything else is
config on yours.

### 3. Contribute a new source, miner, or tool
Every piece here is a small, independent Python package under `packages/`.
`mycelium-collector`'s `sources/` directory shows the pattern for adding a
new data source; `mycelium-substrate`'s `miners.py` shows the pattern for
a new pattern miner (a plain function registered in `MINERS`). PRs welcome.

## systemd — running unattended, as yourself, never root

Every unit in `systemd/` is a `systemctl --user` template. These run as
whichever user installs them — there is no `User=` directive because
there's no need for one; a user unit is non-root by construction. To keep
them running after logout / across reboots without a login session:
```bash
loginctl enable-linger $USER
```
See each `.service`/`.timer` file's header comment for its specific
install steps and config knobs.

## What's genuinely portable vs. what needs verification

Built and **verified with real, local round-trip tests** in this repo
(not just "should work"):
- `mycelium-substrate`: CLI (`init`/`trace`/`list`/`cycle`), sandboxed
  miner execution, and the new HTTP server (`POST /api/trace`,
  `GET /api/traces`) — all confirmed working end to end.
- `mycelium-collector`: registry init, graceful degradation with every
  source disabled/unconfigured, GMGN "binary not found" handling, and a
  full round trip against a live local `mycelium-http` instance.
- `mycelium-cycle`: full chained cycle (mine+apply → publish → a2a)
  against a real local substrate, including graceful handling of unset
  optional credentials (Gitea/Nostr).
- `substrate-tunnel`: argument handling, `--dry-run` command construction,
  and the "autossh not installed" failure path. **Not** tested against a
  real SSH connection to any relay host — that needs an actual target and
  wasn't attempted here per this build's scope (don't touch Fold4/Contabo
  yet).
- `picks-client`: full round trip against a local mock picks server,
  including the failure/non-zero-exit path.

**Built from the orchestration plan's functional spec, not ported from
original source** (the original scripts weren't reachable from this build
environment — no SSH path to Fold4, and touching it wasn't in scope):
`substrate-tunnel` and `picks-client`. Diff both against the real Fold4
scripts before treating them as drop-in replacements there specifically;
they're written to the plan's stated behavior, not verified byte-for-byte
against what's currently running on the phone.

**Genuinely refactored, not just repackaged**: `mycelium-collector` had
two real portability bugs fixed, not just moved — see its own README's
"What changed from the original phone-native version" section. The
biggest: its "Helius" source never actually called Helius, it read
Vantage's local SQLite file directly, which only worked by filesystem
coincidence. Now it's a real Helius API call.

**Scope note on `mycelium-substrate`**: the original substrate has a full
Go-based HTTP gateway (`cryptonomicsed-byte/mycelium`'s `gateway/`) with a
live dashboard, findings UI, WebTransport streaming, and council/picks
proxies — a whole separate product surface. That was **not** ported here;
this repo's `mycelium-http` is a deliberately minimal, stdlib-only Python
substitute covering just the trace ingest/query contract every other tool
in this repo actually depends on. Run the real Go gateway alongside if you
want the dashboard — both can point at the same `MYCELIUM_DB`.

## Repo layout

```
mycelium-tools/
├── install.sh
├── packages/
│   ├── mycelium-substrate/   (U1)
│   ├── mycelium-collector/   (U2)
│   ├── mycelium-cycle/       (U3)
│   ├── substrate-tunnel/     (U4)
│   └── picks-client/         (U5)
└── systemd/                  (--user unit + timer templates, one per tool)
```

> **Moved (P2-01):** these tools now live in [cryptonomicsed-byte/mycelium](https://github.com/cryptonomicsed-byte/mycelium) under `packages/` and `systemd/`. Old `mycelium_substrate` imports keep working through the shim there. Nothing here is removed.
