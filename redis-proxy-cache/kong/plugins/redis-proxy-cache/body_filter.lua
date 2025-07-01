local PLUGIN_NAME = "redis-proxy-cache"
local Storage = require( "kong.plugins." .. PLUGIN_NAME .. ".storage")
local validators = require("kong.plugins." .. PLUGIN_NAME .. ".validators")
local Cache = require("kong.plugins." .. PLUGIN_NAME .. ".cache")
local Encoder = require("kong.plugins." .. PLUGIN_NAME .. ".encoder")

local _M = {}

local function filter_headers(headers)
  headers["Connection"] = nil
  headers["Keep-Alive"] = nil
  headers["Public"] = nil
  headers["Proxy-Authenticate"] = nil
  headers["Transfer-Encoding"] = nil
  headers["Upgrade"] = nil
  headers["Via"] = nil
  headers["X-Kong-Upstream-Latency"] = nil
  headers["X-Kong-Proxy-Latency"] = nil
  headers["X-Cache-Status"] = nil
  return headers
end

local function async_update_cache(config, cache_key, body)
  local cache = Cache:new()
  cache:set_config(config)

  local cache_ttl = cache:cache_ttl()
  local headers = ngx.resp.get_headers(0, true)
  local status = ngx.status

  ngx.timer.at(0, function(premature)
    if premature then return end
    local storage = Storage:new()
    storage:set_config(config)
    if cache_ttl then
      local cache_value = Encoder.encode(status, body, filter_headers(headers))
      storage:set(cache_key, cache_value, cache_ttl)
    end
  end)
end

function _M.execute(config)
  local cache_key = ngx.ctx.cache_key
  local rt_body_chunks = ngx.ctx.rt_body_chunks
  local rt_body_chunk_number = ngx.ctx.rt_body_chunk_number
  local chunk, eof = ngx.arg[1], ngx.arg[2]

  if eof then
    local body = table.concat(rt_body_chunks)
    ngx.arg[1] = body

    if validators.check_response_code(config.response_code, ngx.status)
      and validators.check_request_method() then
      async_update_cache(config, cache_key, body)
    end
  else
    rt_body_chunks[rt_body_chunk_number] = chunk
    ngx.ctx.rt_body_chunk_number = rt_body_chunk_number + 1
    ngx.arg[1] = nil
  end
end

return _M
