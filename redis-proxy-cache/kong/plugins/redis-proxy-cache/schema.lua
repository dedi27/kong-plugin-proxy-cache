local PLUGIN_NAME = "redis-proxy-cache"

--local function server_port(given_value, given_config)
--if given_value > 65534 then
--        return false, "port value too high"
--    end
--end

local function server_port(value)
  if value > 65534 then
    return false, "port value too high"
  end
  return true
end

local schema = {
  name = PLUGIN_NAME,
  fields = {
    {
      config = {
        type = "record",
        fields = {
          {
            response_code = {
              type = "array",
              elements = { type = "string" },
              default = { "200", "301", "302" },
              required = true,
            }
          },
          {
            vary_headers = {
              type = "array",
              elements = { type = "string" },
              required = false,
            }
          },
          {
            vary_nginx_variables = {
              type = "array",
              elements = { type = "string" },
              required = false,
            }
          },
          {
            cache_ttl = {
              type = "number",
              default = 300,
              required = true,
            }
          },
          {
            cache_control = {
              type = "boolean",
              default = true,
            }
          },
          {
            redis = {
              type = "record",
              fields = {
                { host = { type = "string", required = false } },
                { sentinel_master_name = { type = "string", required = false } },
                { sentinel_role = { type = "string", required = false, default = "master" } },
                {
                  sentinel_addresses = {
                    type = "array",
                    elements = { type = "string" },
                    required = false,
                  }
                },
                {
                  port = {
                    type = "number",
                    default = 6379,
                    required = true,
                    custom_validator = server_port,
                  }
                },
                { timeout = { type = "number", default = 2000, required = true } },
                { password = { type = "string", required = false } },
                { database = { type = "number", default = 0, required = true } },
                { max_idle_timeout = { type = "number", default = 10000, required = true } },
                { pool_size = { type = "number", default = 1000, required = true } },
              }
            }
          },
        },
      },
    },
  },
}

return schema