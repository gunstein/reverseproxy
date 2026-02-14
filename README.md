# reverseproxy

Traefik-based reverse proxy that handles HTTPS termination, automatic certificate management, and routing for multiple web applications hosted under `vatnar.no`.

## Architecture

```
Internet (HTTP/HTTPS)
        │
   Traefik (ports 80/443)
   HTTP → HTTPS redirect
   Let's Encrypt TLS
        │
   Docker network "web"
        │
  ┌─────┼─────┬──────────┬──────────┬──────────────┐
  │     │     │          │          │              │
pinball pinball mypage  pinball   pinball       pinball
 2d     3d    server    web      bevy_web      server
                                              (WebSocket
                                               :9001)
```

## Services & Domains

| Domain | Service | Description |
|--------|---------|-------------|
| `gunstein.vatnar.no` | mypage_server | Personal website |
| `pinball2d.vatnar.no` | pinball2d | Pinball 2D game |
| `pinball3d.vatnar.no` | pinball3d | Pinball 3D game |
| `pinball.vatnar.no` | pinball_web + pinball_server | Multiplayer pinball (HTTP + WebSocket on `/ws`) |
| `pinballbevy.vatnar.no` | pinball_bevy_web + pinball_server | Bevy engine pinball client (HTTP + WebSocket on `/ws`) |

## Security & Middleware

**Default chain** (all HTTP routes): gzip compression, security headers (HSTS, XSS filter, frame deny, no MIME sniffing, no-referrer).

**WebSocket chain** (`/ws` routes): compression, rate limiting (30 avg / 60 burst), 50 max in-flight requests.

## Prerequisites

- Docker and Docker Compose
- DNS A records for all subdomains pointing to the server
- Source code at `../source/Pinball2DMulti/` (for `pinball_web`, `pinball_bevy_web`, and `pinball_server` which are built locally)

## Usage

```bash
# Start all services
docker compose up -d

# Start and rebuild locally-built images
docker compose up -d --build

# Stop all services
docker compose down

# View Traefik logs
docker compose logs -f traefik
```

## File Structure

```
.
├── docker-compose.yml          # Service definitions and Traefik CLI config
├── traefik-config/
│   └── dynamic.yml             # Routers, services, and middleware definitions
├── letsencrypt/                # Auto-generated Let's Encrypt certificates (gitignored)
└── README.md
```

## Notes

- Certificates are automatically provisioned via Let's Encrypt (ACME TLS-ALPN challenge) and stored in `./letsencrypt/acme.json`.
- The Traefik API dashboard is enabled but not exposed externally.
- Traefik runs with `no-new-privileges` security restriction.
- Pre-built images (`pinball2d`, `pinball3d`, `mypage_server`) are pulled from Docker Hub under `gunstein/`.
