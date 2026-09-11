#!/bin/sh
set -e
exec java $JAVA_OPTS -Dloader.path=/ext -jar /app/allure-server.jar
