FROM caddy:2.8.1-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/caddyserver/transform-encoder \
    --with github.com/abiosoft/caddy-exec

FROM caddy:2.8.1

COPY --from=builder /usr/bin/caddy /usr/bin/caddy