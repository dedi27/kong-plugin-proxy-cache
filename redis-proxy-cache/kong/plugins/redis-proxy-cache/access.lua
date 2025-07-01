local PLUGIN_NAME = "redis-proxy-cache"
local Storage = require("kong.plugins." .. PLUGIN_NAME .. ".storage")
local validators = require("kong.plugins." .. PLUGIN_NAME .. ".validators")
local Cache = require("kong.plugins." .. PLUGIN_NAME .. ".cache")
local Encoder = require("kong.plugins." .. PLUGIN_NAME .. ".encoder")

local _M = {}

local function render_from_cache(cached_value)
  local response = Encoder.decode(cached_value)

  if response.headers then
    for header, value in pairs(response.headers) do
      kong.response.set_header(header, value)
    end
  end

  kong.response.set_header("X-Cache-Status", "HIT")
  kong.response.exit(response.status, response.content)
end

function _M.execute(config)
  local storage = Storage:new()
  local cache = Cache:new()
  storage:set_config(config)
  cache:set_config(config)

  if not validators.check_request_method() then
    kong.response.set_header("X-Cache-Status", "BYPASS")
    return
  end

  local cache_key = cache:generate_cache_key(ngx.req, ngx.var)
  local cached_value, err = storage:get(cache_key)

  if not (cached_value and cached_value ~= ngx.null) then
    kong.response.set_header("X-Cache-Status", "MISS")
    ngx.ctx.cache_key = cache_key
    ngx.ctx.rt_body_chunks = {}
    ngx.ctx.rt_body_chunk_number = 1
    return
  end

  return render_from_cache(cached_value)
end

return _M
