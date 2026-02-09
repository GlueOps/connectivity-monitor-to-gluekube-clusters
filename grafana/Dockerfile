FROM grafana/grafana:12.4.0-20977568970-ubuntu@sha256:817e4d226bc7d50238e7da67c7413590e36dec8a216e8070bbc77a24f21503d8

COPY datasource.yml /etc/grafana/provisioning/datasources/datasource.yml
COPY grafana.ini /etc/grafana/grafana.ini
COPY dashboard-providers.yml /etc/grafana/provisioning/dashboards/dashboard-providers.yml
COPY dashboards /var/lib/grafana/dashboards