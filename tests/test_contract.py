"""SDK contract sanity — the exact shape adapters + the orchestrator rely on."""
import scanner_sdk as sdk


def test_dataclasses_constructible():
    meta = sdk.EngineMeta(key="zap", name="OWASP ZAP", profiles=("baseline",),
                          dd_scan_type="ZAP Scan", dd_artifact="report.json")
    assert meta.key == "zap"
    req = sdk.ScanRequest(target="https://x", profile="baseline", out_dir="/tmp")
    assert req.options == {}                       # default_factory
    assert sdk.RunHandle(id="1").extra == {}
    assert sdk.Progress(finished=True, error=[], raw={}).error == []
    c = sdk.Collection(summary={}, process={})
    assert c.blocked is None and c.follow_ups == []


def test_registry_roundtrip():
    class FakeEngine:                              # structurally an Engine
        meta = sdk.EngineMeta("fake", "Fake", ("p",), "T", "a.json")
        def healthcheck(self): return "ok"
        def run(self, req): return sdk.RunHandle("1")
        def poll(self, h): return sdk.Progress(True, [], {})
        def collect(self, h, req, progress): return sdk.Collection({}, {})

    e = FakeEngine()
    sdk.register(e)
    assert sdk.get_engine("fake") is e
    assert "fake" in sdk.registered()


def test_risk_code():
    assert sdk.risk_code("High") == 3
    assert sdk.risk_code("  critical ") == 4       # case-insensitive + trimmed
    assert sdk.risk_code("nonsense") == 3          # default
    assert sdk.RISK_NAMES[0] == "Informational"
    assert sdk.RISK_CODES["medium"] == 2


def test_settings_protocol_is_structural():
    class FakeSettings:                            # a test double, no orchestrator dep
        zap_base_url = "http://zap:8080"
        zap_api_key = ""
        templates_dir = "/t"
        user_agent = ""
        plan_timeout_min = 60
        spider_max_duration_min = 5

    s: sdk.Settings = FakeSettings()               # structural — satisfies the Protocol
    assert s.zap_base_url.startswith("http")
