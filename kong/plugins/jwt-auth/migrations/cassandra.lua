local Migrations = {
  {
    name = "2015-07-15-120857-jwt-auth",
    up = function(options)
      return [[
        CREATE TABLE IF NOT EXISTS jwtauth_credentials(
          id uuid,
          consumer_id uuid,
          secret text,
          created_at timestamp,
          secret_is_base64_encoded boolean,
          PRIMARY KEY (id)
        );

        CREATE INDEX IF NOT EXISTS ON jwtauth_credentials(secret);

        CREATE INDEX IF NOT EXISTS jwtauth_consumer_id ON jwtauth_credentials(consumer_id);
      ]]
    end,
    down = function(options)
      return [[
        DROP TABLE jwtauth_credentials;
      ]]
    end
  }
}

return Migrations
