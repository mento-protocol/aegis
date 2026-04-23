FROM grafana/agent:v0.35.0

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:12345/-/healthy || exit 1

# Create a non-root user for security.
# `grafana/agent:v0.35.0` is Debian-based (BusyBox `addgroup`/`adduser -D`
# aren't available) AND already uses GID/UID 1000 for its built-in `grafana`
# account, so we pick 10001 to avoid the collision.
RUN groupadd -g 10001 agent && \
    useradd -u 10001 -g agent -M -s /usr/sbin/nologin agent

# Prometheus WAL directory (configured in agent.yaml as `wal_directory`).
# /etc is owned by root, so the non-root `agent` user can't `mkdir` at
# runtime — pre-create and chown here.
RUN mkdir -p /etc/agent/data && chown -R agent:agent /etc/agent

COPY --chown=agent:agent agent.yaml /etc/agent/agent.yaml

# Switch to non-root user
USER agent