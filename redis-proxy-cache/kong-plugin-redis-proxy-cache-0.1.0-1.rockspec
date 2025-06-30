local plugin_name = "redis-proxy-cache"
local package_name = "kong-plugin-" .. plugin_name
local package_version = "0.1.0"
local rockspec_revision = "1"

local github_account_name = "dedi27"
local github_repo_name = "kong-plugin-redis-proxy-cache"
local git_checkout = package_version == "dev" and "master" or package_version


package = package_name
version = package_version .. "-" .. rockspec_revision
supported_platforms = { "linux", "macosx" }
source = {
  url = "git+https://github.com/"..github_account_name.."/"..github_repo_name..".git",
  branch = git_checkout,
}


description = {
  summary = "Kong is a scalable and customizable API Management Layer built on top of Nginx.",
  homepage = "https://"..github_account_name..".github.io/"..github_repo_name,
  license = "Apache 2.0",
}


dependencies = {
}


build = {
  type = "builtin",
  modules = {
    -- TODO: add any additional code files added to the plugin
    ["kong.plugins."..plugin_name..".handler"] = "kong/plugins/"..plugin_name.."/handler.lua",
    ["kong.plugins."..plugin_name..".schema"] = "kong/plugins/"..plugin_name.."/schema.lua",
    ["kong.plugins."..plugin_name..".access"] = "kong/plugins/"..plugin_name.."/access.lua",
    ["kong.plugins."..plugin_name..".body_filter"] = "kong/plugins/"..plugin_name.."/body_filter.lua",
    ["kong.plugins."..plugin_name..".cache"] = "kong/plugins/"..plugin_name.."/cache.lua",
    ["kong.plugins."..plugin_name..".encoder"] = "kong/plugins/"..plugin_name.."/encoder.lua",
    ["kong.plugins."..plugin_name..".header_filter"] = "kong/plugins/"..plugin_name.."/header_filter.lua",
    ["kong.plugins."..plugin_name..".storage"] = "kong/plugins/"..plugin_name.."/storage.lua",
    ["kong.plugins."..plugin_name..".validators"] = "kong/plugins/"..plugin_name.."/validators.lua"
  },
  dependencies = {
      "lua-resty-redis-connector == 0.11.0"
   }
}
