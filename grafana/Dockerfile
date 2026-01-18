FROM grafana/grafana:12.4.0-20977568970-ubuntu

COPY datasource.yml /etc/grafana/provisioning/datasources/datasource.yml
COPY grafana.ini /etc/grafana/grafana.ini
COPY dashboard-providers.yml /etc/grafana/provisioning/dashboards/dashboard-providers.yml
COPY dashboards /var/lib/grafana/dashboards