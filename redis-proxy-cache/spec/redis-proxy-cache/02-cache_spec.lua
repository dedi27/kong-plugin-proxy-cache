local PLUGIN_NAME = "redis-proxy-cache"
local Cache = require("kong.plugins." .. PLUGIN_NAME .. ".cache")

local function make_request(method, headers)
  return {
    get_method = function()
      return method
    end,
    get_headers = function()
      return headers or {}
    end
  }
end

local function make_ngx(variables)
  local default_variables = {
    request_uri = "request_uri",
    host = "test.com"
  }
  if variables then
    for k, v in pairs(variables) do
      default_variables[k] = v
    end
  end
  return default_variables
end

describe("Proxy Cache: (cache)", function()
  describe("generate_cache_key", function()

    it("should return cache key with 'request_uri'", function()
      local request = make_request("GET")
      local nginx_variables = make_ngx()
      local cache = Cache:new()
      cache:set_config()
      local cache_key = cache:generate_cache_key(request, nginx_variables)
      assert(string.match(cache_key, "request_uri"), "'request_uri' not found in " .. cache_key)
    end)

    it("should return cache key with 'request_method'", function()
      local request = make_request("GET")
      local nginx_variables = make_ngx()
      local cache = Cache:new()
      cache:set_config()
      local cache_key = cache:generate_cache_key(request, nginx_variables)
      assert(string.match(cache_key, "get"), "'request_method' not found in " .. cache_key)
    end)

    it("should return cache key with 'host'", function()
      local request = make_request("GET")
      local nginx_variables = make_ngx()
      local cache = Cache:new()
      cache:set_config()
      local cache_key = cache:generate_cache_key(request, nginx_variables)
      assert(string.match(cache_key, "test.com"), "'host' not found in " .. cache_key)
    end)

    it("should return cache key with header 'Authorization'", function()
      local request = make_request("GET", {
        Authorization = "basic"
      })
      local nginx_variables = make_ngx()
      local config = {
        vary_headers = { "Authorization" }
      }
      local cache = Cache:new()
      cache:set_config(config)
      local cache_key = cache:generate_cache_key(request, nginx_variables)
      assert(string.match(cache_key, "authorization=basic"), "header 'Authorization' not found in " .. cache_key)
    end)

    it("should return cache key with nginx variable 'auth_client_id'", function()
      local request = make_request("GET")
      local nginx_variables = make_ngx({
        auth_client_id = "abcd1234"
      })
      local config = {
        vary_nginx_variables = { "auth_client_id" }
      }
      local cache = Cache:new()
      cache:set_config(config)
      local cache_key = cache:generate_cache_key(request, nginx_variables)
      assert(string.match(cache_key, "auth_client_id=abcd1234"), "nginx variable 'auth_client_id' not found in " .. cache_key)
    end)

    it("should return cache key with nginx variables 'auth_client_id' and 'auth_email'", function()
      local request = make_request("GET")
      local nginx_variables = make_ngx({
        auth_client_id = "abcd1234",
        auth_email = "xxx@mail.com"
      })
      local config = {
        vary_nginx_variables = { "auth_client_id", "auth_email" }
      }
      local cache = Cache:new()
      cache:set_config(config)
      local cache_key = cache:generate_cache_key(request, nginx_variables)
      assert(string.match(cache_key, "auth_client_id=abcd1234"), "nginx variable 'auth_client_id' not found in " .. cache_key)
      assert(string.match(cache_key, "auth_email=xxx@mail.com"), "nginx variable 'auth_email' not found in " .. cache_key)
    end)

  end)
end)
