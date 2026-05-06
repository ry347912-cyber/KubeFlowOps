from flask import Flask, jsonify, request
import datetime
import platform
import os

app = Flask(__name__)

# ─────────────────────────────────────────
#  Routes
# ─────────────────────────────────────────

@app.route("/")
def home():
    return jsonify({
        "app":     "DevOps CI/CD Platform",
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "status":  "running",
        "author":  os.getenv("AUTHOR", "Your Name"),
        "time":    datetime.datetime.utcnow().isoformat() + "Z"
    })

@app.route("/health")
def health():
    return jsonify({
        "status":   "healthy",
        "uptime":   "running",
        "python":   platform.python_version(),
        "hostname": platform.node()
    }), 200

@app.route("/api/info")
def info():
    return jsonify({
        "environment": os.getenv("ENVIRONMENT", "production"),
        "region":      os.getenv("AWS_REGION", "ap-south-1"),
        "build":       os.getenv("BUILD_NUMBER", "local"),
        "commit":      os.getenv("GIT_COMMIT", "unknown"),
        "deployed_at": os.getenv("DEPLOY_TIME", "unknown")
    })

@app.route("/api/echo", methods=["POST"])
def echo():
    data = request.get_json(force=True, silent=True) or {}
    return jsonify({"echo": data, "received_at": datetime.datetime.utcnow().isoformat()})

# ─────────────────────────────────────────

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug = os.getenv("DEBUG", "false").lower() == "true"
    app.run(host="0.0.0.0", port=port, debug=debug)
