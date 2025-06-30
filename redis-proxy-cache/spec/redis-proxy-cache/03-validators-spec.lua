local PLUGIN_NAME = "redis-proxy-cache"
local Validators = require("kong.plugins." .. PLUGIN_NAME .. ".validators")
local schema = require("kong.plugins." .. PLUGIN_NAME .. ".schema")

describe("Validators:", function()
  describe("Response Code:", function()
    local default_response_code

    setup(function()
      for _, field in ipairs(schema.fields) do
        if field.config then
          for _, subfield in ipairs(field.config.fields) do
            if subfield.response_code then
              default_response_code = subfield.response_code.default
              break
            end
          end
        end
      end
    end)

    it("should validate a default response_code", function()
      assert(Validators.check_response_code(default_response_code, 200))
      assert(Validators.check_response_code(default_response_code, 301))
      assert(Validators.check_response_code(default_response_code, 302))
    end)

    it("should not validate a response_code that isn't in schema default", function()
      assert.is_false(Validators.check_response_code(default_response_code, 500))
    end)
  end)
end)
