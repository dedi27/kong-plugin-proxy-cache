local helpers = require "spec.helpers"
local redis = require "resty.redis"
local PLUGIN_NAME = "redis-proxy-cache"

for _, strategy in helpers.each_strategy() do
  describe("Proxy Cache: (access) [#" .. strategy .. "]", function()
    local proxy_client
    local red = redis:new()

    lazy_setup(function()
      local bp = helpers.get_db_utils(strategy)

      local route1 = bp.routes:insert({ hosts = { "test1.com" } })
      local route2 = bp.routes:insert({ hosts = { "test2.com" } })
      local route3 = bp.routes:insert({ hosts = { "responsecode.com" } })
      local route4 = bp.routes:insert({ hosts = { "test-cache-control.com" } })

      bp.plugins:insert {
        name = PLUGIN_NAME,
        route_id = route1.id,
        config = {
          cache_control = false,
          redis = { host = "localhost" },
        },
      }

      bp.plugins:insert {
        name = PLUGIN_NAME,
        route_id = route2.id,
        config = {
          cache_control = true,
          redis = { host = "localhost" },
        },
      }

      bp.plugins:insert {
        name = "request-transformer",
        route_id = route2.id,
        config = {
          add = {
            headers = "Cache-Control:max-age=2",
          },
        },
      }

      bp.plugins:insert {
        name = PLUGIN_NAME,
        route_id = route3.id,
        config = {
          cache_control = false,
          redis = { host = "localhost" },
          response_code = { "404" },
        },
      }

      bp.plugins:insert {
        name = PLUGIN_NAME,
        route_id = route4.id,
        config = {
          cache_control = true,
          redis = { host = "localhost" },
        },
      }

      assert(helpers.start_kong({
        database = strategy,
        nginx_conf = "spec/fixtures/custom_nginx.template",
        plugins = "bundled," .. PLUGIN_NAME,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      proxy_client = helpers.proxy_client()
      local ok, err = red:connect("localhost", 6379)
      assert(ok, err)
    end)

    after_each(function()
      if proxy_client then proxy_client:close() end
      red:flushall()
      red:set_keepalive(1000, 100)
    end)

    describe("request methods", function()
      it("caches when method is GET", function()
        local response = proxy_client:get("/", {
          headers = { host = "test1.com" }
        })
        local cached_value, err = red:get("get:/")
        assert(cached_value, err)
        assert.is_truthy(cached_value)
      end)

      it("caches when method is HEAD", function()
        local response = proxy_client:send {
          path = "/",
          method = "HEAD",
          headers = { host = "test1.com" }
        }
        local cached_value, err = red:get("head:/")
        assert(cached_value, err)
        assert.is_truthy(cached_value)
      end)

      it("does not cache when method is POST", function()
        local response = proxy_client:post("/", {
          headers = { host = "test1.com" }
        })
        local cached_value, err = red:get("post:/")
        assert(cached_value, err)
        assert.is_truthy(cached_value)
      end)
    end)

    describe("response headers", function()
      after_each(function()
        red:flushall()
      end)

      it("contains 'MISS' in 'X-Cache-Status' on first access", function()
        local response = proxy_client:get("/", {
          headers = { host = "test1.com" }
        })
        assert.equal("MISS", response.headers["X-Cache-Status"])
      end)

      it("contains 'HIT' in 'X-Cache-Status' on second access", function()
        proxy_client:get("/status/200", {
          headers = { host = "test1.com" }
        })

        local proxy_client2 = helpers.proxy_client()
        local response = proxy_client2:get("/status/200", {
          headers = { host = "test1.com" }
        })

        assert.equal("HIT", response.headers["X-Cache-Status"])
      end)

      it("contains 'BYPASS' in 'X-Cache-Status' when method is POST", function()
        local response = proxy_client:post("/", {
          headers = { host = "test1.com" }
        })
        assert.equal("BYPASS", response.headers["X-Cache-Status"])
      end)

      it("contains 'BYPASS' in 'X-Cache-Status' when response is 404", function()
        local response = proxy_client:get("/404", {
          headers = { host = "test1.com" }
        })
        assert.equal("BYPASS", response.headers["X-Cache-Status"])
      end)

      describe("when request has Cache-Control", function()
        it("contains 'MISS' when Cache-Control is not present", function()
          local response = proxy_client:get("/", {
            headers = { host = "test-cache-control.com" }
          })
          assert.equal("MISS", response.headers["X-Cache-Status"])
        end)

        it("contains 'MISS' when cache key expires", function()
          proxy_client:get("/status/200", {
            headers = { host = "test2.com" }
          })

          ngx.sleep(3)

          local proxy_client2 = helpers.proxy_client()
          local response = proxy_client2:get("/status/200", {
            headers = { host = "test2.com" }
          })

          assert.equal("MISS", response.headers["X-Cache-Status"])
        end)
      end)

      describe("response code behavior", function()
        after_each(function()
          red:flushall()
        end)

        it("caches default response code 200", function()
          local response1 = proxy_client:get("/", {
            headers = {
              host = "test1.com",
              ["Cache-Control"] = "max-age=400"
            }
          })
          assert.equal("MISS", response1.headers["X-Cache-Status"])
          assert.equal(200, response1.status)

          local proxy_client2 = helpers.proxy_client()
          local response2 = proxy_client2:get("/", {
            headers = { host = "test1.com" }
          })

          assert.equal("HIT", response2.headers["X-Cache-Status"])
          assert.equal(200, response2.status)
        end)

        it("does not cache 404 by default", function()
          local response1 = proxy_client:get("/status/404", {
            headers = {
              host = "test1.com",
              ["Cache-Control"] = "max-age=400"
            }
          })
          assert.equal("BYPASS", response1.headers["X-Cache-Status"])
          assert.equal(404, response1.status)

          local proxy_client2 = helpers.proxy_client()
          local response2 = proxy_client2:get("/status/404", {
            headers = { host = "test1.com" }
          })
          assert.equal("BYPASS", response2.headers["X-Cache-Status"])
          assert.equal(404, response2.status)
        end)

        it("caches 404 when configured", function()
          local response1 = proxy_client:get("/status/404", {
            headers = { host = "responsecode.com" }
          })
          assert.equal("MISS", response1.headers["X-Cache-Status"])
          assert.equal(404, response1.status)

          local proxy_client2 = helpers.proxy_client()
          local response2 = proxy_client2:get("/status/404", {
            headers = { host = "responsecode.com" }
          })
          assert.equal("HIT", response2.headers["X-Cache-Status"])
          assert.equal(404, response2.status)
        end)
      end)
    end)
  end)
end
