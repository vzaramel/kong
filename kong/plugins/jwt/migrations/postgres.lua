local Migration = {
  {
    name = "m2015-06-09-jwt-auth",

    up = function(options)
      return [[
        CREATE TABLE IF NOT EXISTS jwt_secrets(
          id uuid,
          consumer_id uuid REFERENCES consumers (id) ON DELETE CASCADE,
          key text,
          secret text,
          created_at timestamp without time zone default (now() at time zone 'utc'),
          PRIMARY KEY (id)
        );

        DO $$
        BEGIN
        IF (
          SELECT to_regclass('public.jwt_secrets_key')
            ) IS NULL THEN
          CREATE INDEX jwt_secrets_key ON jwt_secrets(key);
        END IF;

        IF (
          SELECT to_regclass('public.jwt_secrets_secret')
            ) IS NULL THEN
          CREATE INDEX jwt_secrets_secret ON jwt_secrets(secret);
        END IF;

        IF (
          SELECT to_regclass('public.jwt_secrets_consumer_id')
            ) IS NULL THEN
          CREATE INDEX jwt_secrets_consumer_id ON jwt_secrets(consumer_id);
        END IF;

        END$$;
      ]]
    end,

    down = function(options)
      return [[
        DROP TABLE jwt_secrets;
      ]]
    end
  }
}

return Migration
