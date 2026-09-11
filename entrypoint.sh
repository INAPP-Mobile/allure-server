#!/bin/sh
set -e

# Railway volumes mount as root:root; upstream expects uid 1000 (app:app).
# Chown only if currently root-owned (avoids flooding logs on named-volume restarts).
if [ "$(stat -c %u /allure 2>/dev/null || echo 0)" = "0" ]; then
  chown -R app:app /allure 2>/dev/null || true
fi

# Drop to the non-root app user and exec the original Spring Boot jar.
exec gosu app:app sh -c 'exec java $JAVA_OPTS -Dloader.path=/ext -jar /app/allure-server.jar'
