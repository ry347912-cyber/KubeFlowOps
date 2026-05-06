import pytest
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app import app

# ─────────────────────────────────────────
#  Fixtures
# ─────────────────────────────────────────

@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c

# ─────────────────────────────────────────
#  Tests
# ─────────────────────────────────────────

def test_home_returns_200(client):
    res = client.get("/")
    assert res.status_code == 200

def test_home_has_status_field(client):
    res = client.get("/")
    data = res.get_json()
    assert data["status"] == "running"

def test_home_has_app_name(client):
    res = client.get("/")
    data = res.get_json()
    assert "CI/CD" in data["app"]

def test_health_returns_200(client):
    res = client.get("/health")
    assert res.status_code == 200

def test_health_is_healthy(client):
    res = client.get("/health")
    data = res.get_json()
    assert data["status"] == "healthy"

def test_info_endpoint(client):
    res = client.get("/api/info")
    assert res.status_code == 200
    data = res.get_json()
    assert "environment" in data

def test_echo_endpoint(client):
    payload = {"message": "hello", "test": True}
    res = client.post("/api/echo", json=payload)
    assert res.status_code == 200
    data = res.get_json()
    assert data["echo"]["message"] == "hello"

def test_echo_empty_body(client):
    res = client.post("/api/echo")
    assert res.status_code == 200

def test_unknown_route_returns_404(client):
    res = client.get("/this-does-not-exist")
    assert res.status_code == 404
