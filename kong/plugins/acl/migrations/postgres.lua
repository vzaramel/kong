local Migrations = {
  {
    name = "m2015-08-25-841841_init_acl",
    up = function(options)
      return [[
        CREATE TABLE IF NOT EXISTS acls(
          id uuid,
          consumer_id uuid REFERENCES consumers (id) ON DELETE CASCADE,
          "group" text,
          created_at timestamp without time zone default (now() at time zone 'utc'),
          PRIMARY KEY (id)
        );

        DO $$
        BEGIN
        IF (
          SELECT to_regclass('public.acls_group')
            ) IS NULL THEN
          CREATE INDEX acls_group ON acls("group");
        END IF;

        IF (
          SELECT to_regclass('public.acls_consumer_id')
            ) IS NULL THEN
          CREATE INDEX acls_consumer_id ON acls(consumer_id);
        END IF;

        END$$;
      ]]
    end,
    down = function(options)
      return [[
        DROP TABLE acls;
      ]]
    end
  }
}

return Migrations
