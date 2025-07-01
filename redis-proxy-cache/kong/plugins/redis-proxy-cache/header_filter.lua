local PLUGIN_NAME = "redis-proxy-cache"
local validators = require("kong.plugins." .. PLUGIN_NAME .. ".validators")

local _M = {}

function _M.execute(config)
  if not validators.check_response_code(config.response_code, kong.response.get_status()) then
    kong.response.set_header("X-Cache-Status", "BYPASS")
  end
end

return _M
