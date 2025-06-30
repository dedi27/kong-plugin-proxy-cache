local PLUGIN_NAME = "redis-proxy-cache"

local access = require("kong.plugins." .. PLUGIN_NAME .. ".access")
local body_filter = require("kong.plugins." .. PLUGIN_NAME .. ".body_filter")
local header_filter = require("kong.plugins." .. PLUGIN_NAME .. ".header_filter")


local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1", -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
}
-- ProxyCaching

function plugin:access(conf)
  local ok, err = pcall(access.execute, conf)
  if not ok then
    kong.log.err("proxy-cache access error: ", err)
  end
end

function plugin:header_filter(conf)
  local ok, err = pcall(header_filter.execute, conf)
  if not ok then
    kong.log.err("proxy-cache header_filter error: ", err)
  end
end

function plugin:body_filter(conf)
  local rt_body_chunks = ngx.ctx.rt_body_chunks
  local is_miss = ngx.header["X-Cache-Status"] == "MISS"
  if rt_body_chunks and is_miss then
    local ok, err = pcall(body_filter.execute, conf)
    if not ok then
      kong.log.err("proxy-cache body_filter error: ", err)
    end
  end
end

return plugin