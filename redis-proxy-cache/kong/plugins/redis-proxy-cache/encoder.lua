local cjson = require("cjson.safe")

local _M = {}

function _M.encode(status, content, headers)
  local payload = {
    status = status,
    content = content,
    headers = headers,
  }

  local json, err = cjson.encode(payload)
  if not json then
    kong.log.err("failed to encode cache payload: ", err)
  end
  return json
end

function _M.decode(str)
  local data, err = cjson.decode(str)
  if not data then
    kong.log.err("failed to decode cache payload: ", err)
  end
  return data
end

return _M
