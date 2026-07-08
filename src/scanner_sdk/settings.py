"""The settings read-interface an engine adapter relies on.

The orchestrator owns the concrete, env-derived Settings (including secrets like
`zap_api_key`); an adapter only READS a handful of fields. This Protocol IS that
contract — an adapter types against it, and its tests pass a plain fake object,
so no adapter needs the orchestrator's concrete Settings (or a cross-repo import)
to run standalone.

Structural (duck) typing: any object exposing these attributes satisfies it; the
orchestrator's real Settings does, without declaring the Protocol.
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
