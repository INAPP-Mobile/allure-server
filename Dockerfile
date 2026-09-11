# syntax=docker/dockerfile:1.7
# Wrapper: upstream allure-server runs as uid 1000; Railway volumes mount as root.
# Fix: run as root so the app can write to the root-owned Railway volume.
FROM kochetkovma/allure-server:3.0.1

USER root

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Actuator health endpoint (spring-boot-starter-actuator) gates orchestrator readiness.
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
