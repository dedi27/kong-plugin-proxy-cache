local _M = {}

function _M.check_response_code(allowed_codes, actual_status)
  for _, code in ipairs(allowed_codes) do
    if tonumber(code) == actual_status then
      return true
    end
  end
  return false
end

function _M.check_request_method()
  local method = kong.request.get_method()
  return method == "GET" or method == "HEAD"
end

return _M
