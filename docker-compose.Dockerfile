FROM redis:7-alpine AS base
FROM scratch
COPY --from=base /lib/ld-musl-x86_64.so.1 /lib/
COPY --from=base /usr/lib/libcrypto.so.3 /usr/lib/
COPY --from=base /usr/lib/libssl.so.3 /usr/lib/
COPY --from=base /etc/ssl/certs /etc/ssl/certs
COPY --from=base /usr/share/zoneinfo /usr/share/zoneinfo
COPY backend/stridemoor-api-linux /app/server
COPY backend/configs /app/configs
EXPOSE 8080
WORKDIR /app
ENTRYPOINT ["./server"]
