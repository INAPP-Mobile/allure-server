# Allure Server — Self-Hosted Test Report Dashboard

A self-hosted server for storing, aggregating, and managing Allure test results and generating Allure reports. Ingest `allure-results` produced by any Allure 2 adapter, browse runs, trends, and categories in a web UI — without sending your test data to a third party.

# Deploy and Host

Host your own Allure Server on Railway. This template provisions a single service with a persistent volume for all test data (results, reports, H2 database).

[![Deploy to Railway](https://railway.app/button.svg)](https://railway.com/deploy/luminous-essence)

## Features

- **Allure 2 ingestion** — upload `allure-results` produced by any Allure 2 adapter (Java, Python, JS, .NET, etc.)
- **Report generation** — automatic and on-demand report generation from raw results
- **Trends & categories** — historical trends, severity breakdowns, environment tags, retry tracking
- **Web UI** — server-rendered JTE templates with Tailwind CSS; no SPA build step
- **Basic auth** — bootstrap admin seeded on first startup; manage users via `/app/admin/users`
- **OAuth2 (optional)** — Google SSO via `application-oauth.yaml` profile
- **Plugin loader** — drop JARs under `/ext` and `PropertiesLauncher` picks them up
- **Embedded H2** — zero external database to manage; everything persists under `/allure`
- **Cleanup policy** — automatic retention-based cleanup of old results and reports

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | HTTP port the server listens on | `8080` |
| `BASIC_AUTH_USERNAME` | Bootstrap admin username | `admin` |
| `BASIC_AUTH_PASSWORD` | Bootstrap admin password (change after first login) | random 32-char |

## Architecture

```
CI / CLI ──► allure-server (:8080) ──► /allure (persistent volume)
                                         ├── allure/db/        (H2 database)
                                         ├── allure/results/   (uploaded results)
                                         ├── allure/reports/   (generated reports)
                                         └── ext/              (plugin JARs)
```

- **allure-server** — Spring Boot 3 service on Temurin JRE 25 Alpine
- **H2 embedded** — file-based database at `./allure/db`; no external DB required
- **Persistent volume** — mounted at `/allure`; stores all data across restarts
- **Non-root runtime** — upstream runs as uid 1000; wrapper entrypoint chowns the volume and drops privileges

## About Hosting

Allure Server is a single-service app on Railway:

1. **Allure Server** — stateless Spring Boot service with a persistent volume mounted at `/allure`

All application data (results, reports, H2 database, configuration) lives under `/allure`. The service itself is stateless and can be rebuilt without data loss as long as the volume remains attached.

### Persistent Storage

The service mounts a 5 GB volume at `/allure`. All test results, generated reports, the H2 database, and server settings persist across restarts and deploys.

### Scaling

- Allure Server is a single-instance app (H2 does not support multi-writer setups)
- Scale vertically by increasing the volume size for more historical data
- For high-availability use cases, consider the PostgreSQL variant (see upstream docs)

## Why Deploy

- **Data privacy** — test results often contain sensitive stack traces, environment variables, and internal URLs. Self-hosting keeps that data under your control.
- **No egress fees** — uploading gigabytes of screenshots and videos to a third-party S3-compatible service costs money; Railway's volume is included.
- **Custom retention** — the built-in cleanup policy keeps 90 days of results by default; tune per-path retention to match your CI cadence.
- **Plugin ecosystem** — drop custom Allure Server plugin JARs under `/ext` without rebuilding the image.

## Dependencies for Deployment

### Deployment Dependencies

- **Railway account** — required to host the service
- **Railway volume** — automatically provisioned (5 GB) and mounted at `/allure`
- **Docker Hub access** — the image `kochetkovma/allure-server:3.0.1` is pulled from Docker Hub during deploy

No external databases, object stores, or third-party accounts are required. The embedded H2 database handles all persistence.

## Common Use Cases

- **CI test reporting** — Jenkins, GitHub Actions, GitLab CI, or any CI system uploads `allure-results` artifacts to the server after each pipeline run
- **Local development** — developers generate Allure reports locally and upload to a shared team server for collaboration
- **Regulated environments** — organizations that cannot send test data to SaaS tools due to compliance requirements
- **Cost-sensitive teams** — replace paid Allure TestOps or third-party report hosting with a self-hosted alternative

## First-Run Steps

1. Click **Deploy on Railway** above
2. After deploy, open the service URL (e.g., `https://allure-server-production-*.up.railway.app`)
3. Log in with the bootstrap credentials:
   - Username: `admin`
   - Password: copy from the **Variables** tab (`BASIC_AUTH_PASSWORD`)
4. Navigate to **Admin → Users** to change the password and add team members
5. Configure your CI pipeline to POST `allure-results` to `/api/results`

## Uploading Results

```bash
# Zip your allure-results directory
zip -r allure-results.zip allure-results/

# Upload to the server (replace with your URL and credentials)
curl -u admin:password \
  -X POST \
  -H "Content-Type: multipart/form-data" \
  -F "file=@allure-results.zip" \
  https://allure-server-production-*.up.railway.app/api/results
```

## Source

Upstream: [kochetkov-ma/allure-server](https://github.com/kochetkov-ma/allure-server) — Java 25, Spring Boot 3, Gradle 9, JTE templating, H2 embedded.
