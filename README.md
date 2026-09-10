# DevOps.Scanner.SDK

<!-- BADGES:START -->
[![CI (GitHub)](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)](https://github.com/PandaFosec/DevOps.Scanner.SDK/actions/workflows/ci.yml) ![Python](https://img.shields.io/badge/python-3.14-3776AB?logo=python&logoColor=white)
<!-- BADGES:END -->

![python](https://img.shields.io/badge/python-3.14-blue)

The **shared scanner-engine plugin contract** for the DevOps security-scan stack.

One dependency-free source of truth that both the orchestrator and every
`DevOps.Scanner.*` engine adapter (ZAP, Nuclei, tlsx) build on — so an adapter
never needs a cross-repo `PYTHONPATH` to import the core, and its tests run
standalone.

## What's in it

| Module | Contents |
|---|---|
| `scanner_sdk.engine` | Engine contract dataclasses (`EngineMeta`, `ScanRequest`, `RunHandle`, `Progress`, `Collection`), the `Engine` `Protocol`, and the shared `register` / `get_engine` / `registered` registry |
| `scanner_sdk.risk` | Severity ordering: `RISK_NAMES`, `RISK_CODES`, `risk_code()` |
| `scanner_sdk.settings` | `Settings` `Protocol` — the read-interface an adapter relies on (the orchestrator provides the concrete, env-derived object at runtime; tests pass a fake) |

Top-level re-exports let consumers `from scanner_sdk import Engine, ScanRequest, register, RISK_NAMES, ...`.

## Design

- **Engine-agnostic and dependency-free** — imports no scanner and no
  orchestrator code. This is the contract, nothing else.
- **Plugin loading is the host's policy.** An adapter self-registers on import
  (`register(...)`); the host decides *which* plugin modules to import and then
  reads them back via `get_engine` / `registered`.
- Public on purpose: the contract holds **no secrets**, so the private adapter
  repos can depend on it in CI without a token.

## Use

```toml
# in a consumer's pyproject.toml
dependencies = ["scanner-sdk"]

[tool.uv.sources]
scanner-sdk = { git = "https://github.com/PandaFosec/DevOps.Scanner.SDK" }
```

## Develop

```bash
mise install            # python + uv per mise.toml
uv run pytest -q
```

## Layered `.env` config

Root `.env` is a minimal bootstrap: `DATA_DIR` only. Any script that needs
config sources it via `scripts/lib/load-env.sh`, which additionally (and
optionally) layers in, in order — later overriding earlier:

1. `$REPO/.env` — bootstrap (`DATA_DIR`)
2. `$DATA_DIR/config/common/.env` — values shared across `DevOps.*` repos,
   defined once instead of duplicated per-repo
3. `$DATA_DIR/config/DevOps.Scanner.SDK/.env` — this repo's own overrides,
   if any

Every layer past the bootstrap is optional; a missing file is today's
(unchanged) behavior. This repo has no runtime `.env` consumers today (the
SDK itself takes no secrets — see Design above); `scripts/lib/load-env.sh` is
provided so any future host-side script adopts the same cascade instead of
duplicating it. See `.env.template` for the full list of variables and where
each one belongs.

