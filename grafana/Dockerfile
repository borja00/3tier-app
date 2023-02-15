FROM grafana/grafana-oss:8.2.6


COPY cloudwatch.yml /etc/grafana/provisioning/datasources/
COPY dashboards.yml /etc/grafana/provisioning/dashboards/
COPY dashboards/* /var/lib/grafana/dashboards/