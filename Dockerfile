FROM kong/kong:3.9.1

LABEL VERSION=3.9
LABEL DESC="Kong with redis-proxy-cache plugin"

USER root
RUN apt update && apt -y upgrade && apt install -y curl unzip git
RUN luarocks install lua-resty-redis-connector && chown -R kong:kong /usr/local/share/lua/5.1/
RUN git clone https://github.com/dedi27/kong-plugin-proxy-cache.git /tmp/redis-proxy-cache && \
    cd /tmp/redis-proxy-cache && \
    git checkout dev && \
    luarocks make kong-plugin-proxy-cache-0.1.0-1.rockspec --lua-version=5.1 && \
    chown -R kong:kong /usr/local/share/lua/5.1/kong/plugins/redis-proxy-cache

#ADD redis-proxy-cache /tmp/redis-proxy-cache
#WORKDIR /tmp/kong-plugin-proxy-cache
#RUN luarocks make kong-plugin-proxy-cache-2.0.0-1.rockspec --lua-version=5.1
#RUN luarocks make *.rockspec"
#RUN luarocks make --lua-version=5.1 --tree=/usr/local/share/lua/5.1/kong/plugins/proxy-cache rockspecs/kong-plugin-proxy-cache-0.1-1.rockspec 
#RUN chown -R kong:kong /usr/local/share/lua/5.1/kong/plugins/proxy-cache

#RUN luarocks install kong-plugin-proxy-cache && chown -R kong:kong /usr/local/share/lua/5.1/kong/plugins/proxy-cache
RUN ls /usr/local/share/lua/5.1/kong/plugins
WORKDIR /

USER kong