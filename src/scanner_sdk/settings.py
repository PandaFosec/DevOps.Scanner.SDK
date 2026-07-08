"""The settings read-interface an engine adapter relies on + the host injection
point.

The host (the orchestrator) owns the concrete, env-derived Settings (including
secrets like `zap_api_key`); an adapter only READS a handful of fields. Two
pieces:

- `Settings` — the read Protocol an adapter types against.
- `settings` proxy + `configure_settings()` — the host installs its concrete
  Settings once at startup; adapters read `scanner_sdk.settings.<field>` through
  the stable proxy. In tests an adapter installs a plain fake. This is what lets
  an adapter depend ONLY on the SDK — never on the orchestrator's settings module
  or a cross-repo import.
"""
from __future__ import annotations

from typing import Protocol


class Settings(Protocol):
    zap_base_url: str
    zap_api_key: str
    templates_dir: str
    user_agent: str
    plan_timeout_min: int
    spider_max_duration_min: int


class _SettingsProxy:
    """A stable object adapters import once; attribute reads delegate to the
    host-injected concrete Settings. Reading before the host has configured it is
    a programming error (raises) rather than a silent `None`."""
    __slots__ = ()
    _impl: Settings | None = None      # class-level; installed by configure_settings

    def __getattr__(self, name: str):
        impl = _SettingsProxy._impl
        if impl is None:
            raise RuntimeError(
                "scanner_sdk settings not configured — the host must call "
                "scanner_sdk.configure_settings(...) before an adapter reads config"
            )
        return getattr(impl, name)


settings = _SettingsProxy()


def configure_settings(impl: Settings) -> None:
    """Install the host's concrete Settings. The orchestrator calls this once at
    startup; a test installs a fake. Pass any object exposing the `Settings`
    fields (structural typing — no need to subclass the Protocol)."""
    _SettingsProxy._impl = impl
