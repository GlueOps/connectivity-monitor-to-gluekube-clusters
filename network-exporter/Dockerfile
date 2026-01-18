FROM syepes/network_exporter:1.8.0@sha256:00af1691570e84bb0d8839d934e1ca10e9ee018385463609e03a8137e0ea9c56

WORKDIR /app/cfg

COPY generate_network_exporter.sh ./generate_network_exporter.sh

RUN chmod +x ./generate_network_exporter.sh && apk add --no-cache bash curl jq

ENV API_KEY=""

CMD /app/cfg/generate_network_exporter.sh "$API_KEY" && /app/network_exporter --config.file=/app/cfg/network_exporter.yml