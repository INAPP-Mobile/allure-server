# syntax=docker/dockerfile:1.7
# Wrapper: upstream allure-server runs as uid 1000; Railway volumes mount as root.
# Fix: root entrypoint chowns the data dir, then drops to the app user via gosu.
FROM kochetkovma/allure-server:3.0.1

USER root
RUN apk add --no-cache gosu

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
