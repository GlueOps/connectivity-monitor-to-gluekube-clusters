FROM syepes/network_exporter:1.8.0

WORKDIR /app/cfg

COPY generate_network_exporter.sh ./generate_network_exporter.sh

RUN chmod +x ./generate_network_exporter.sh && apk add --no-cache bash curl jq

ENV API_KEY=""

CMD /app/cfg/generate_network_exporter.sh "$API_KEY" && /app/network_exporter --config.file=/app/cfg/network_exporter.yml