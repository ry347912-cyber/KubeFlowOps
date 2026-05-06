"""
Performance Gate — Locust Load Test
Runs in CI pipeline. Deployment is BLOCKED if thresholds not met.

Thresholds (fail = no deploy):
  - P95 response time  < 200ms
  - Error rate         < 1%
  - Min RPS            > 50

Usage:
  locust -f performance/locustfile.py \
    --host=http://localhost:5000 \
    --headless -u 50 -r 10 --run-time 60s \
    --csv=perf_results --exit-code-on-error 1
"""

from locust import HttpUser, task, between, events
from locust.runners import MasterRunner
import json, time, os

# ─────────────────────────────────────────
#  Thresholds
# ─────────────────────────────────────────
P95_THRESHOLD_MS   = 200   # ms
ERROR_RATE_MAX_PCT = 1.0   # percent
MIN_RPS            = 50    # requests per second


# ─────────────────────────────────────────
#  User Behaviours
# ─────────────────────────────────────────

class APIUser(HttpUser):
    """Simulates a real user hitting the API endpoints."""
    wait_time = between(0.5, 2.0)

    @task(5)
    def get_home(self):
        with self.client.get("/", catch_response=True) as resp:
            if resp.status_code == 200:
                data = resp.json()
                if data.get("status") != "running":
                    resp.failure("Unexpected status value")
            else:
                resp.failure(f"Got {resp.status_code}")

    @task(10)
    def health_check(self):
        with self.client.get("/health", catch_response=True) as resp:
            if resp.status_code == 200:
                if resp.json().get("status") != "healthy":
                    resp.failure("Not healthy")
            else:
                resp.failure(f"Got {resp.status_code}")

    @task(3)
    def get_info(self):
        self.client.get("/api/info")

    @task(2)
    def post_echo(self):
        payload = {"test": True, "load_test": True, "timestamp": time.time()}
        with self.client.post("/api/echo", json=payload, catch_response=True) as resp:
            if resp.status_code == 200:
                data = resp.json()
                if "echo" not in data:
                    resp.failure("Missing echo field")
            else:
                resp.failure(f"Got {resp.status_code}")


# ─────────────────────────────────────────
#  Gate validation on test end
# ─────────────────────────────────────────

@events.quitting.add_listener
def check_thresholds(environment, **kwargs):
    """
    Called when test ends. Checks stats against thresholds.
    Non-zero exit code = deployment blocked in CI.
    """
    stats   = environment.runner.stats
    total   = stats.total

    failures  = total.fail_ratio * 100
    rps       = total.current_rps
    p95       = total.get_response_time_percentile(.95) or 0

    print("\n" + "─"*50)
    print("⚡ PERFORMANCE GATE — Results")
    print("─"*50)
    print(f"  P95 Response Time : {p95:.0f}ms  (threshold: <{P95_THRESHOLD_MS}ms)")
    print(f"  Error Rate        : {failures:.2f}%  (threshold: <{ERROR_RATE_MAX_PCT}%)")
    print(f"  Avg RPS           : {rps:.1f}      (threshold: >{MIN_RPS})")
    print("─"*50)

    failed = False
    if p95 > P95_THRESHOLD_MS:
        print(f"❌ FAIL — P95 {p95:.0f}ms exceeds {P95_THRESHOLD_MS}ms limit")
        failed = True
    if failures > ERROR_RATE_MAX_PCT:
        print(f"❌ FAIL — Error rate {failures:.2f}% exceeds {ERROR_RATE_MAX_PCT}% limit")
        failed = True
    if rps < MIN_RPS and rps > 0:
        print(f"❌ FAIL — RPS {rps:.1f} below minimum {MIN_RPS}")
        failed = True

    if failed:
        print("🚫 DEPLOYMENT BLOCKED — Performance gate failed!")
        environment.process_exit_code = 1
    else:
        print("✅ PASS — All thresholds met. Deployment allowed.")

        # Save results for dashboard
        results = {
            "p95_ms":       round(p95),
            "error_rate":   round(failures, 2),
            "rps":          round(rps, 1),
            "total_reqs":   total.num_requests,
            "total_fails":  total.num_failures,
            "avg_ms":       round(total.avg_response_time),
            "passed":       True,
            "timestamp":    time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        }
        with open("perf_results.json", "w") as f:
            json.dump(results, f, indent=2)
        print(f"📊 Results saved to perf_results.json")
