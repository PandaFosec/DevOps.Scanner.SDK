"""Severity ordering shared by the orchestrator and every engine adapter.

Codes 0-3 are ZAP's native riskcodes; 4 (Critical) is engine-agnostic headroom —
ZAP never emits it, but Nuclei (and others) do. Higher code = more severe.
"""

from __future__ import annotations

RISK_NAMES = {0: "Informational", 1: "Low", 2: "Medium", 3: "High", 4: "Critical"}
RISK_CODES = {v.lower(): k for k, v in RISK_NAMES.items()}


def risk_code(name: str) -> int:
    """Map a risk name (case-insensitive) to its severity code (0..4)."""
    return RISK_CODES.get(name.strip().lower(), 3)
