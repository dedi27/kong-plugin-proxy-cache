#!/usr/bin/env bash

# Nome do plugin
export PLUGIN_NAME="redis-proxy-cache"

# Plugins que o Kong deve carregar (inclui os padrões + o seu)
export KONG_PLUGINS="bundled,$PLUGIN_NAME"

# Porta do Redis (caso você queira rodar um Redis local para testes)
export REDIS_HOST="localhost"
export REDIS_PORT="6379"

# Versão do Kong a ser usada (opcional, pode ser ajustada conforme necessário)
export KONG_VERSION="3.6.1.0"

# Caminho para o rockspec (ajustado automaticamente)
export ROCKSPEC=$(ls kong-plugin-$PLUGIN_NAME-*.rockspec | head -n 1)

# Comando padrão para rodar os testes
function run_tests() {
  pongo build --force
  pongo run
}

# Executa o comando passado ou os testes por padrão
if [[ "$1" != "" ]]; then
  exec "$@"
else
  run_tests
fi
