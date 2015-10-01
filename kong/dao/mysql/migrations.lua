local mysql = require "luasql.mysql"
local stringy = require "stringy"
local BaseDao = require "kong.dao.mysql.base_dao"

local Migrations = BaseDao:extend()

function Migrations:new(properties)
  self._table = "schema_migrations"
  self.queries = {
    add_migration = [[
      UPDATE schema_migrations SET migrations = CONCAT(migrations, '%s') where id = '%s'
    ]],
    get_all_migrations = [[
      SELECT * FROM schema_migrations;
    ]],
    insert_migrations = "INSERT INTO schema_migrations (id,migrations) VALUES ('%s', '{}')",
    get_all_migrations = "SELECT id,migrations FROM schema_migrations",
    get_migrations = "SELECT id,migrations FROM schema_migrations where id = '%s'",
    delete_migration = "UPDATE schema_migrations SET migrations = array_remove(migrations, '%s') WHERE id = '%s'",
    get_migrations_table = "SELECT table_name FROM information_schema.tables WHERE table_name ='schema_migrations';",
    reset_all_tables = [[
      drop schema public cascade;
      create schema public;
    ]]
  }

  Migrations.super.new(self, properties)
end

function Migrations:keyspace_exists(keyspace)
  local rows = Migrations.super._execute(self, self.queries.get_migrations_table)

  if not rows then
    return nil, "Error getting table"
  else
    return rows[1]["table_name"] == "schema_migrations"
  end
end

-- Log (add) given migration to schema_migrations table.
-- @param migration_name Name of the migration to log
-- @return query result
-- @return error if any
function Migrations:add_migration(migration_name, identifier)
  local rows
  rows = Migrations.super._execute(self, string.format(self.queries.get_migrations, identifier))
  -- print(rows)
  if #rows == 0 then
    Migrations.super._execute(self, string.format(self.queries.insert_migrations, identifier))
  end

  return Migrations.super._execute(self,
    string.format(self.queries.add_migration, migration_name, identifier))
end

-- Return all logged migrations with a filter by identifier optionally. Check if keyspace exists before to avoid error during the first migration.
-- @param identifier Only return migrations for this identifier.
-- @return A list of previously executed migration (as strings)
-- @return error if any
function Migrations:get_migrations(identifier)
  local keyspace_exists, err = self:keyspace_exists()
  if err then
    return nil, err
  elseif not keyspace_exists then
    -- keyspace is not yet created, this is the first migration
    return nil
  end

  local rows

  if identifier ~= nil then
    rows = Migrations.super._execute(self, string.format(self.queries.get_migrations, identifier))
  else
    rows = Migrations.super._execute(self, self.queries.get_all_migrations)
  end

  if not rows then
    return nil, "Error getting migrations"
  elseif rows and #rows > 0 then
    return identifier == nil and rows or rows[1].migrations
  end
end

-- Unlog (delete) given migration from the schema_migrations table.
-- @return query result
-- @return error if any
function Migrations:delete_migration(migration_name, identifier)
  return Migrations.super._execute(self,
    self.queries.delete_migration,
    {mysql.list({migration_name}), identifier},
    {consistency_level = mysql.constants.consistency.ALL}
  )
end

-- Drop the entire keyspace
-- @param `keyspace` Name of the keyspace to drop
-- @return query result
function Migrations:drop_keyspace(keyspace)
  return Migrations.super._execute(self, string.format("DROP keyspace \"%s\"", keyspace))
end

function Migrations:drop()
  -- never drop this
end

return { migrations = Migrations }
