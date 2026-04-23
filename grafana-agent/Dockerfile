FROM grafana/agent:v0.35.0

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:12345/-/healthy || exit 1

# Create a non-root user for security.
# `grafana/agent:v0.35.0` is Debian-based, so BusyBox-style `addgroup`/
# `adduser -D` aren't available — use groupadd/useradd instead.
RUN groupadd -g 1000 agent && \
    useradd -u 1000 -g agent -M -s /usr/sbin/nologin agent

COPY agent.yaml /etc/agent/agent.yaml

# Switch to non-root user
USER agent