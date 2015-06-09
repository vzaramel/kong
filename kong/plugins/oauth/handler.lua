local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.oauth.access"

local OAuthHandler = BasePlugin:extend()

function OAuthHandler:new()
  OAuthHandler.super.new(self, "keyauth")
end

function OAuthHandler:access(conf)
  OAuthHandler.super.access(self)
  access.execute(conf)
end

OAuthHandler.PRIORITY = 1000

return OAuthHandler
