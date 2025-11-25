# trunk-ignore-all(terrascan/AC_DOCKER_0047)
FROM grafana/agent:v0.35.0

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:12345/-/healthy || exit 1

# Create a non-root user for security
RUN addgroup -g 1000 agent && \
    adduser -D -u 1000 -G agent agent

COPY agent.yaml /etc/agent/agent.yaml

# Switch to non-root user
USER agent