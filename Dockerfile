# ============================================
# gl-epti — GitLab CE Lab Optimizado
# Bootcamp Zero to Hero
# ============================================
# Build:
#   docker build -t gl-epti:19 .
#   docker build --build-arg GITLAB_VERSION=19.1.1-ce.0 -t gl-epti:19.1 .
# ============================================

ARG GITLAB_VERSION=19.1.1-ce.0
FROM gitlab/gitlab-ce:${GITLAB_VERSION}

LABEL org.opencontainers.image.title="gl-epti"
LABEL org.opencontainers.image.description="GitLab CE on-premises optimizado para laboratorio Bootcamp Zero to Hero"
LABEL org.opencontainers.image.source="https://github.com/ergrato-dev/bc-gitlab"
LABEL org.opencontainers.image.version="19"

# ── Parches de seguridad del SO base + herramientas de lab ──
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
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
        gnupg \
        iproute2 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ── Trivy: escaner de CVEs (auditoria dentro del contenedor) ──
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
        | gpg --dearmor -o /usr/share/keyrings/trivy.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
        > /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends trivy \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ── Scripts de utilidad para el lab ──
COPY --chmod=755 scripts/lab/ /usr/local/bin/

# ── Configuraciones pre-armadas ──
COPY config/lab/ /opt/lab-config/

# ── Variables por defecto (sobrescribibles en runtime) ──
ENV LAB_MODE=true
ENV LAB_SKIP_TELEMETRY=true

# GitLab usa el entrypoint original del omnibus
# La configuracion se inyecta via GITLAB_OMNIBUS_CONFIG en runtime
