# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

A research/demo platform for **Server-Sent Events in a distributed deployment**: three Spring Boot backend instances behind Nginx, with Redis pub/sub keeping messages in sync so a client on any instance receives broadcasts. A React + TypeScript dashboard connects to instances, sends broadcast / private / server-targeted messages, and shows per-instance metrics.

See `README.md` (English summary + detailed 中文 guide) for ports and architecture diagrams.

## Commands

```bash
# Full stack, HTTP (dev): frontend :3000, nginx :80, backends :8080-8082, redis :6379
docker compose up --build -d
docker compose logs -f backend-1

# Full stack, HTTPS/HTTP2 (prod): frontend :3443, nginx :443, backends :8443-8445, Redis Commander :8090
scripts\generate-ssl-docker.bat          # first run only — creates keystore/certs
docker compose -f docker-compose-prod.yml up --build -d

# Backend only (needs Redis on localhost:6379)
docker run -d -p 6379:6379 redis:7-alpine
cd backend && ./gradlew bootRun          # :8080, Java 21
cd backend && ./gradlew build            # compile check (no tests exist yet)

# Frontend only
cd frontend && npm install
npm run dev                              # :5173, proxies /api → localhost:8080
npm run build                            # tsc && vite build
npm run lint                             # eslint, --max-warnings 0
```

Smoke checks: `curl http://localhost/health`, `curl -N "http://localhost:8080/api/sse/stream?clientId=test"`, Swagger UI at `/swagger-ui.html`, actuator at `/actuator/health`.

The helper scripts in `scripts/` are **Windows `.bat` / PowerShell** (start/stop, SSL generation, distribution and HTTP/2 tests). On macOS/Linux use the docker compose commands above directly.

## Layout

```
backend/   Spring Boot 3.3, Java 21, Gradle, Lombok
  controller/SseController.java   all HTTP endpoints under /api/sse
  service/SseService.java         connection registry, Redis pub/sub, heartbeat, metrics
  config/                         RedisConfig, WebConfig (CORS), OpenApiConfig
  model/                          DTOs (SseMessage, BroadcastRequest, ClientConnection, …)
  resources/application.yml       defaults; application-http2.yml for SSL/HTTP2
frontend/  React 18 + Vite 5 + axios; almost everything lives in src/App.tsx (~900 lines)
nginx/     nginx.conf (HTTP), nginx-http2.conf + Dockerfile-nginx-http2 (HTTPS)
redis/     redis.conf, redis-performance.conf
scripts/   Windows helper scripts
```

## How messaging works

- `GET /api/sse/stream?clientId=…` creates a `Sinks.Many` per client, stored in an in-memory `ConcurrentHashMap` on **that instance only**.
- Broadcast: publish to Redis channel `sse:broadcast`; every instance subscribes and emits to its local clients.
- Server-targeted: publish to `sse:server:<instanceId>`; only that instance subscribes.
- Private message `POST /broadcast/{clientId}`: **local lookup only** — errors with "Client not connected to this instance" if the client is on another instance. To reach a client elsewhere, use `POST /broadcast/server/{serverId}/client/{clientId}` (routed via `sse:server:<serverId>`).
- Instance discovery: each instance writes `sse:instance:<instanceId>` with a 2-minute TTL, refreshed on a schedule; `/api/sse/servers` scans that prefix.
- Heartbeat every 30 s (`app.sse.heartbeat-interval`); stream timeout 1 h.

When changing message flow, keep the rule: **anything that must reach a client on another instance goes through Redis**. Keep Redis key/channel names as the constants at the top of `SseService`.

## Conventions and gotchas

- **Servlet vs WebFlux.** `build.gradle` includes both `spring-boot-starter-web` and `spring-boot-starter-webflux`, and `spring.main.web-application-type` is not set, so Spring Boot starts as a **servlet (Tomcat / MVC)** app that returns `Flux`/`Mono`. `WebConfig` implements `WebFluxConfigurer`, which only takes effect in a reactive app. Check which stack is actually running before changing CORS, filters, or server config, and don't add a second CORS mechanism without removing the dead one.
- **Profiles.** Compose sets `SPRING_PROFILES_ACTIVE=docker` (prod: `docker,http2,secure`), but only `application-http2.yml` exists. Config comes from env vars in the compose files plus `application.yml` defaults.
- **Instance identity** comes from `INSTANCE_ID` / `INSTANCE_NAME` env vars; locally it falls back to a random UUID. Metrics and targeting depend on it.
- **Nginx and SSE.** `/api` must keep `proxy_buffering off` and long read timeouts, or events arrive in bursts. The upstream uses `ip_hash` (sticky by client IP).
- **Frontend bypasses Nginx.** `App.tsx` builds instance URLs as `http(s)://localhost:<port>` (8080–8082 or 8443–8445, chosen from `window.location.protocol`), so the browser talks to backends directly and CORS matters. `CORS_ORIGINS` defaults to `:5173` and `:3000`; add `:3443` if needed for HTTPS.
- **SSL.** Keystore is `classpath:ssl/keystore.p12`, password `changeit`, alias `sse-demo` — demo-only values. Never commit real certs or keys (`ssl/` dirs hold READMEs only).
- **Language.** Docs and UI text are Traditional Chinese with some Simplified in code comments/logs. Keep identifiers and log keys in English.
- **No tests yet.** If you add them, put JUnit 5 + `reactor-test` (`StepVerifier`) under `backend/src/test/java`; Redis-dependent tests need a running Redis or Testcontainers.
- `spring-boot-properties-migrator` in `build.gradle` is marked temporary; it can be removed once config warnings are clean.
