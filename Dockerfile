# ============================================
# gl-epti — GitLab CE Lab Optimizado
# Bootcamp Zero to Hero
# ============================================
# Build:
#   docker build -t gl-epti:17 .
#   docker build --build-arg GITLAB_VERSION=17.11.8-ce.0 -t gl-epti:17.11 .
# ============================================

ARG GITLAB_VERSION=19.1.1-ce.0
FROM gitlab/gitlab-ce:${GITLAB_VERSION}

LABEL org.opencontainers.image.title="gl-epti"
LABEL org.opencontainers.image.description="GitLab CE on-premises optimizado para laboratorio Bootcamp Zero to Hero"
LABEL org.opencontainers.image.source="https://github.com/ergrato-dev/bc-gitlab"
LABEL org.opencontainers.image.version="19"

# ── Capa de herramientas de laboratorio ──
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        jq \
        curl \
        wget \
        vim \
        nano \
        tree \
        htop \
        less \
        netcat-openbsd \
        dnsutils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ── Scripts de utilidad para el lab ──
COPY --chmod=755 scripts/lab/ /usr/local/bin/

# ── Configuraciones pre-armadas ──
COPY config/lab/ /opt/lab-config/

# ── Healthcheck mejorado ──
HEALTHCHECK --interval=30s --timeout=10s --retries=20 --start-period=300s \
    CMD curl -fs http://localhost/-/health || exit 1

# ── Variables por defecto (sobrescribibles en runtime) ──
ENV LAB_MODE=true
ENV LAB_SKIP_TELEMETRY=true

# GitLab usa el entrypoint original del omnibus
# La configuracion se inyecta via GITLAB_OMNIBUS_CONFIG en runtime
