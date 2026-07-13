"""DevOps.Scanner.SDK — the shared scanner-engine plugin contract.

One source of truth for the engine adapter contract (dataclasses + `Engine`
Protocol + registry), the severity constants, and the settings read-interface —
shared by the orchestrator and every DevOps.Scanner.* engine adapter, so no
adapter needs a cross-repo PYTHONPATH to import the core.
"""

from scanner_sdk.config import Settings, configure_settings, settings
from scanner_sdk.engine import (
    Collection,
    Engine,
    EngineMeta,
    Progress,
    RunHandle,
    ScanRequest,
    get_engine,
    register,
    registered,
)
from scanner_sdk.risk import RISK_CODES, RISK_NAMES, risk_code

__all__ = [
    "Collection",
    "Engine",
    "EngineMeta",
    "Progress",
    "RunHandle",
    "ScanRequest",
    "get_engine",
    "register",
    "registered",
    "RISK_NAMES",
    "RISK_CODES",
    "risk_code",
    "Settings",
    "settings",
    "configure_settings",
]
