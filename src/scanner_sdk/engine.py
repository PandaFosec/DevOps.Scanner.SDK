"""Scanner-engine plugin contract + registry (the shared SDK).

The orchestrator drives engines through this contract; each concrete engine (a
ZAP / Nuclei / tlsx adapter) implements `Engine` and self-registers via
`register()`. This module is ENGINE-AGNOSTIC and dependency-free — it imports no
scanner and no orchestrator code, so every adapter and the orchestrator share
ONE source of truth for the contract (no cross-repo PYTHONPATH).

Plugin-LOADING policy — which adapter modules to import, and from where — is the
host's concern, not the SDK's: the host imports its plugin modules (which
self-register on import) and then reads them back via `get_engine`/`registered`.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol


@dataclass(frozen=True)
class EngineMeta:
    key: str                       # "zap", "nuclei"
    name: str                      # "OWASP ZAP"
    profiles: tuple[str, ...]      # engine scan modes (ZAP: baseline|full|api)
    dd_scan_type: str              # DefectDojo native parser name
    dd_artifact: str               # report file imported to DefectDojo


@dataclass
class ScanRequest:
    target: str
    profile: str
    out_dir: str
    options: dict[str, Any] = field(default_factory=dict)


@dataclass
class RunHandle:                   # opaque engine bookkeeping (plan_id, pid, container id…)
    id: str
    extra: dict[str, Any] = field(default_factory=dict)


@dataclass
class Progress:
    finished: bool
    error: list[str]               # [] = ok
    raw: dict[str, Any]


@dataclass
class Collection:
    summary: dict[str, Any]        # {counts, total, alerts}
    process: dict[str, Any]        # crawl/telemetry for rendering + scan state
    blocked: str | None = None     # engine "no meaningful coverage" reason → FAILED verdict
    follow_ups: list["ScanRequest"] = field(default_factory=list)


class Engine(Protocol):
    meta: EngineMeta
    def healthcheck(self) -> str: ...
    def run(self, req: ScanRequest) -> RunHandle: ...
    def poll(self, h: RunHandle) -> Progress: ...
    def collect(self, h: RunHandle, req: ScanRequest,
                progress: dict[str, Any]) -> Collection: ...


# --- Registry ------------------------------------------------------------- #
# A plugin self-registers on import; the host reads engines back by key. Pure
# in/out — no auto-loading here (that policy belongs to the host).
_REGISTRY: dict[str, Engine] = {}


def register(engine: Engine) -> None:
    """Add an engine to the shared registry (a plugin calls this on import)."""
    _REGISTRY[engine.meta.key] = engine


def get_engine(key: str) -> Engine:
    """The registered engine for `key`. Raises KeyError if the host hasn't
    imported that plugin module yet."""
    return _REGISTRY[key]


def registered() -> dict[str, Engine]:
    """All registered engines keyed by `meta.key`."""
    return dict(_REGISTRY)
