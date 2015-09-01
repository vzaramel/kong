local constants = require "kong.constants"
local IO = require "kong.tools.io"
local yaml = require "yaml"

function load_configuration()
  -- where do we get KONG_CONF from?
  local configuration_paths = { os.getenv("KONG_CONF"), IO.configuration_path, "kong.yml" }
  local configuration_file = nil
  local paths_checked = ""

  for _,path in pairs(configuration_paths)
  do
    paths_checked = paths_checked .. path
    if IO.file_exists(path) then
      configuration_file = IO.read_file(path)
    end
    if configuration_file then
      break
    end
  end
  if not configuration_file then
    error("No configuration file at: "..paths_checked)
  end

  local configuration = yaml.load(configuration_file)
  return configuration
end

local configuration = load_configuration()

return require("kong.dao." .. configuration.database .. ".base_dao")