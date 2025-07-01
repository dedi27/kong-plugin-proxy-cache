FROM kong/kong:3.9.1

LABEL VERSION=3.9.1
LABEL DESC="Kong with redis-proxy-cache plugin"

USER root
RUN apt update && apt -y upgrade && apt install -y curl unzip git
RUN luarocks install lua-resty-redis-connector && chown -R kong:kong /usr/local/share/lua/5.1/
RUN git clone https://github.com/dedi27/kong-plugin-proxy-cache.git /tmp/redis-proxy-cache && \
    cd /tmp/redis-proxy-cache && \
    cd redis-proxy-cache && \
    luarocks make kong-plugin-redis-proxy-cache-0.1.0-1.rockspec --lua-version=5.1 && \
    chown -R kong:kong /usr/local/share/lua/5.1/kong/plugins/redis-proxy-cache && \
    cd /tmp && \
    rm -rf /tmp/redis-proxy-cache
RUN ls /usr/local/share/lua/5.1/kong/plugins
USER kong