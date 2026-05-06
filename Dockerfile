# ─────────────────────────────────────────
#  Stage 1 — Builder
# ─────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Install deps in isolated layer (cache-friendly)
COPY app/requirements.txt .
RUN pip install --upgrade pip \
 && pip install --prefix=/install -r requirements.txt

# ─────────────────────────────────────────
#  Stage 2 — Production Image
# ─────────────────────────────────────────
FROM python:3.11-slim AS production

# Security: non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY app/ .

# Build metadata labels
ARG APP_VERSION=1.0.0
ARG BUILD_NUMBER=local
ARG GIT_COMMIT=unknown

LABEL org.opencontainers.image.title="DevOps CI/CD Platform" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.description="Production Flask API — CI/CD Demo" \
      maintainer="Your Name"

# Environment
ENV APP_VERSION=${APP_VERSION} \
    BUILD_NUMBER=${BUILD_NUMBER} \
    GIT_COMMIT=${GIT_COMMIT} \
    ENVIRONMENT=production \
    PORT=5000 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Switch to non-root
USER appuser

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

# Gunicorn — production WSGI server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", \
     "--timeout", "60", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
