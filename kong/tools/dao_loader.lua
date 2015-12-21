local _M = {}

function _M.load(config, spawn_cluster)
  local DaoFactory = require("kong.dao."..config.database..".factory")
  _M.database = database
  _M.BaseDao = require('kong.dao.'..config.database..'.base_dao')
  return DaoFactory(config.dao_config, config.plugins_available, spawn_cluster)
end

return _M
