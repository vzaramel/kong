describe("dao", function()
  it("should load a dao", function()
    local IO = require("kong.tools.io")
    local dao = require("kong.dao")
    assert.truthy(dao)
    assert.truthy(dao.prepare_stmt)
  end)
  -- it("should load a dao from config passed in via cli", function()

  --   local IO = require("kong.tools.io")
  --   IO.configuration_path = 'kong_TEST.yml'
  --   spy.on(IO, "file_exists")
  --   local dao = require("kong.dao")

  --   assert.truthy(dao)
  --   assert.truthy(dao.prepare_stmt)
  --   assert.spy(IO.file_exists).was_called_with("kong_TEST.yml")

  --   IO.file_exists:revert()
  -- end)
end)