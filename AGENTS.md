# AI Agent Instructions

Guidelines for AI agents working on this codebase.

## Project Overview

A Docker Compose stack that monitors network connectivity to GlueKube cluster servers via ICMP ping.

## Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Service orchestration - 3 services: grafana-glueops-gluekube-monitor, prometheus-glueops-gluekube-monitor, network-exporter-glueops-gluekube-monitor |
| `network-exporter/generate_network_exporter.sh` | Fetches server IPs from AutoGlue API, generates targets config |
| `network-exporter/Dockerfile` | Runs generate script at startup, then network_exporter |
| `grafana/dashboards/gluekube.json` | Main Grafana dashboard (legacy JSON format required) |
| `prometheus/prometheus.yml` | Scrape config - targets network-exporter-glueops-gluekube-monitor:9427 |

## Architecture

```
network-exporter-glueops-gluekube-monitor (port 9427) → prometheus-glueops-gluekube-monitor (port 9090) → grafana-glueops-gluekube-monitor (port 3000/60080)
       ↓
  AutoGlue API (fetches cluster/server IPs at startup)
```

## Common Tasks

### Adding a new metric/dashboard panel

1. Edit `grafana/dashboards/gluekube.json`
2. Use Prometheus datasource UID: `prometheus`
3. Query `ping_rtt_seconds` metric with labels: `name`, `type`

### Modifying target generation

1. Edit `network-exporter/generate_network_exporter.sh`
2. Target naming: `{cluster_name}-{role}-{hostname}`
3. API endpoint: `https://autoglue.glueopshosted.com/api/v1`

### Adding environment variables

1. Add to `docker-compose.yml` under the relevant service
2. Document in README.md

## API Reference

The `generate_network_exporter.sh` script uses these AutoGlue API endpoints:

- `GET /orgs` - List organizations (requires `X-API-KEY` header)
- `GET /clusters` - List clusters (requires `X-API-KEY` and `X-Org-ID` headers)
- `GET /clusters/{id}` - Get cluster details with nested `node_pools[].servers[]` and `bastion_server`

## Coding Conventions

- Shell scripts: Use `set -euo pipefail`, prefer `local` variables
- YAML: 2-space indentation
- Docker: One Dockerfile per service subdirectory

## Do NOT

- Commit API keys or `.env` files
- Use Grafana's new v2beta1 dashboard format (file provisioning requires legacy format)
- Modify prometheus.yml scrape targets - they reference container names from docker-compose
