# Connectivity Monitor to GlueKube Clusters

Monitor network connectivity to all GlueKube cluster servers using ICMP ping metrics, visualized in Grafana.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  network-       │     │   prometheus    │     │    grafana      │
│  exporter       │────▶│                 │────▶│                 │
│  (ICMP pings)   │     │  (scrapes       │     │  (dashboards)   │
│                 │     │   metrics)      │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │
        ▼
   AutoGlue API
   (fetches server IPs)
```

## Quick Start

### Prerequisites

- Docker and Docker Compose
- AutoGlue API key (user API key from https://autoglue.glueopshosted.com)

### Running

```bash
# Option 1: Pass API key directly
API_KEY="your-api-key-here" docker-compose up --build

# Option 2: Use .env file
echo "API_KEY=your-api-key-here" > .env
docker-compose up --build
```

Access Grafana at http://localhost (port 80)

- **Username:** `admin`
- **Password:** `grafana`

### Clean Restart

To completely reset all data (Grafana settings, Prometheus metrics):

```bash
docker-compose down -v --rmi all
API_KEY="your-api-key" docker-compose up --build
```

## Project Structure

```
├── docker-compose.yml          # Main orchestration file
├── grafana/
│   ├── Dockerfile              # Grafana image with provisioning
│   ├── grafana.ini             # Grafana configuration
│   ├── datasource.yml          # Prometheus datasource config
│   ├── dashboard-providers.yml # Dashboard provisioning config
│   └── dashboards/
│       └── gluekube.json       # Main connectivity dashboard
├── prometheus/
│   ├── Dockerfile              # Prometheus image
│   └── prometheus.yml          # Scrape configuration
└── network-exporter/
    ├── Dockerfile              # Network exporter image
    └── generate_network_exporter.sh  # Fetches IPs from AutoGlue API
```

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `API_KEY` | Yes | AutoGlue user API key |
| `GF_SECURITY_ADMIN_USER` | No | Grafana admin username (default: `admin`) |
| `GF_SECURITY_ADMIN_PASSWORD` | No | Grafana admin password (default: `grafana`) |

### Data Retention

Prometheus is configured to retain metrics for 2 days (`--storage.tsdb.retention.time=2d`). Modify in `docker-compose.yml` if needed.

### Adding/Updating Dashboards

1. Create/modify dashboard in Grafana UI
2. Export: Share → Export → Enable "Export for sharing externally"
3. Save JSON to `grafana/dashboards/`
4. Rebuild: `docker-compose up --build`

## How It Works

1. **Startup:** `generate_network_exporter.sh` calls the AutoGlue API to fetch all clusters and servers
2. **Target generation:** Creates ICMP ping targets for every server with a public IP
3. **Naming convention:** `{cluster_name}-{role}-{hostname}` (e.g., `prod-cluster-master-node1`)
4. **Monitoring:** Network exporter pings all targets, Prometheus scrapes metrics, Grafana visualizes

## Troubleshooting

### No data in Grafana

1. Check network-exporter logs: `docker-compose logs network-exporter`
2. Verify API key is valid
3. Ensure servers have public IPs in AutoGlue

### Dashboard not loading

1. Check datasource: Grafana → Connections → Data sources → Prometheus → Test
2. Verify Prometheus is scraping: http://localhost:9090/targets

### Containers won't start

```bash
docker-compose down -v --rmi all
docker-compose up --build
```

## Security

- **Never commit API keys** - use `.env` file and add `.env` to `.gitignore`
- The API key is passed as an environment variable at runtime
