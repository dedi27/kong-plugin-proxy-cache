local redis_connector = require("resty.redis.connector")

local _M = {}

function _M:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function _M:set_config(config)
  local redis_conf = config.redis or {}

  local redis_config = {
    host = redis_conf.host,
    port = redis_conf.port,
    password = redis_conf.password,
    db = redis_conf.database,
    read_timeout = redis_conf.timeout,
    keepalive_timeout = redis_conf.max_idle_timeout,
    keepalive_poolsize = redis_conf.pool_size,
  }

  if redis_conf.sentinel_master_name and #redis_conf.sentinel_master_name > 0 then
    redis_config.master_name = redis_conf.sentinel_master_name
    redis_config.role = redis_conf.sentinel_role

    if redis_conf.sentinel_addresses then
      redis_config.sentinels = {}
      for _, sentinel in ipairs(redis_conf.sentinel_addresses) do
        local host, port = string.match(sentinel, "^(.-):(%d+)$")
        if host and port then
          table.insert(redis_config.sentinels, {
            host = host,
            port = tonumber(port),
          })
        end
      end
    end
  end

  self.connector = redis_connector.new(redis_config)
end

function _M:connect()
  local red, err = self.connector:connect()
  if not red then
    kong.log.err("failed to connect to Redis: ", err)
    return false
  end
  self.red = red
  return true
end

function _M:close()
  local ok, err = self.connector:set_keepalive(self.red)
  if not ok then
    kong.log.err("failed to set Redis keepalive: ", err)
    return false
  end
  return true
end

function _M:set(key, value, expire_time)
  if not self:connect() then return end

  local ok, err = self.red:set(key, value)
  if not ok then
    kong.log.err("failed to set Redis cache: ", err)
    return
  end

  self.red:expire(key, expire_time)
  self:close()
end

function _M:get(key)
  if not self:connect() then return nil end

  local value, err = self.red:get(key)
  if err then
    kong.log.err("failed to get Redis cache: ", err)
    return nil, err
  end

  self:close()
  return value
end

return _M
