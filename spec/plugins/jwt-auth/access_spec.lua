local spec_helper = require "spec.spec_helpers"
local http_client = require "kong.tools.http_client"
local cjson = require "cjson"
local jwt = require "jwt"

local STUB_GET_URL = spec_helper.STUB_GET_URL
local STUB_POST_URL = spec_helper.STUB_POST_URL
local pubkey = [[
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3h3hbKXM40yH18djU0eM
asMIJ2jEtRn4DzJEcPvRDu+zFUzzNqSUFbD6pYIv/S+C31edIvyfi9kxMdZOKEIm
AHasLJ6PTBej+ruzIWHNf2Yse7+egXEit5bcKb3J9FOpCDHE+YjM4S9QaQT2hr30
Y7iIVcNURJn0k2T6HL+AVt0oUbupUdJjS9S5GUSQ0F74t74J9g7X4sOSTjl3RBxB
mUzfYor3w1HVwP+R0awAzSlNYZdWWJJM6aZXH76nqfv6blKTW0on12b71YWRWKYP
GxG1KwES6v5+PeLzlJDIDRcI8pl49fJYoXyasF8pskS63o9q8ibQspk+nzL9lD4E
EQIDAQAB
-----END PUBLIC KEY-----
]]

describe("Authentication Plugin", function()

  describe("JWT Authentication when secret is text", function()

    setup(function()
      spec_helper.prepare_db()
      spec_helper.insert_fixtures {
        api = {
          { name = "tests jwt-auth", inbound_dns = "jwtauth.com", upstream_url = "http://mockbin.com" },
          { name = "tests jwt-auth 2", inbound_dns = "jwtauth2.com", upstream_url = "http://mockbin.com" }
        },
        consumer = {
          { username = "jwt-auth_tests_consumer" },
          { username = "rs256_user" }
        },
        plugin = {
          { name = "jwt-auth", config = { }, __api = 1 },
          { name = "jwt-auth", config = { id_names = { "username" }, hide_credentials = true }, __api = 2 },
        },
        jwtauth_credential = {
          { secret = "example_key", __consumer = 1 },
          { secret = pubkey, __consumer = 2 }
        }
      }

      spec_helper.start_kong()
    end)

    teardown(function()
      spec_helper.stop_kong()
    end)


    it("should return invalid credentials when the credential value is wrong", function()
      local response, status = http_client.get(STUB_GET_URL, {id = "jwt-auth_tests_consumer"}, {host = "jwtauth.com", authorization = "asd"})
      local body = cjson.decode(response)
      assert.are.equal(400, status)
      assert.are.equal("Invalid authentication credentials", body.message)
    end)

    it("should return invalid credentials when only passing authorization", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "jwtauth.com", authorization = "asd"})
      local body = cjson.decode(response)
      assert.are.equal(400, status)
      assert.are.equal("Invalid authentication credentials", body.message)
    end)

    it("should return invalid credentials when only passing id", function()
      local response, status = http_client.get(STUB_GET_URL, {id = "jwt-auth_tests_consumer"}, {host = "jwtauth.com"})
      local body = cjson.decode(response)
      assert.are.equal(400, status)
      assert.are.equal("Invalid authentication credentials", body.message)
    end)

    it("should return invalid credentials when the credential parameter name is wrong in GET", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "jwtauth.com", authorization123 = "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="})
      local body = cjson.decode(response)
      assert.are.equal(400, status)
      assert.are.equal("Invalid authentication credentials", body.message)
    end)

    it("should return invalid credentials when the credential parameter name is wrong in POST", function()
      local response, status = http_client.post(STUB_POST_URL, {}, {host = "jwtauth.com", authorization123 = "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="})
      local body = cjson.decode(response)
      assert.are.equal(400, status)
      assert.are.equal("Invalid authentication credentials", body.message)
    end)

    it("should pass with GET", function()
      local key = "example_key"

      local payload = {
          iss = "12345678",
          nbf = os.time(),
          exp = os.time() + 3600,
      }

      local token = jwt.encode(claims, {alg = "HS256", keys = {private = key}})
      local response, status = http_client.get(STUB_GET_URL, {id = "jwt-auth_tests_consumer"}, {host = "jwtauth.com", authorization = "Bearer " .. token})
      assert.are.equal(200, status)
      local parsed_response = cjson.decode(response)
      assert.are.equal("Bearer " .. token, parsed_response.headers.authorization)
    end)

    it("should work with RS256", function()
      local token = "eyJhbGciOiJSUzI1NiJ9.eyJqdGkiOiJhOGZjZTFkZi1iNGFlLTRjNDEtYmFjNi1iNWJiZjI4MGMyOWMiLCJzdWIiOiI3YmZjNThlYy03N2RkLTQ4NzQtYmViZC1iYTg0MTAzMDEyNzkiLCJzY29wZSI6WyJvYXV0aC5hcHByb3ZhbHMiLCJvcGVuaWQiXSwiY2xpZW50X2lkIjoibG9naW4iLCJjaWQiOiJsb2dpbiIsImdyYW50X3R5cGUiOiJwYXNzd29yZCIsInVzZXJfaWQiOiI3YmZjNThlYy03N2RkLTQ4NzQtYmViZC1iYTg0MTAzMDEyNzkiLCJ1c2VyX25hbWUiOiJhZG1pbkBmb3Jpby5jb20iLCJlbWFpbCI6ImFkbWluQGZvcmlvLmNvbSIsImlhdCI6MTM5ODkwNjcyNywiZXhwIjoxMzk4OTQ5OTI3LCJpc3MiOiJodHRwOi8vbG9jYWxob3N0Ojk3NjMvdWFhL29hdXRoL3Rva2VuIiwiYXVkIjpbIm9hdXRoIiwib3BlbmlkIl19.xOa5ZpXksgoaA_XJ3yHMjlLcbSoM6XJy-e60zfyP7bRmu0EKEGZdZrl2iJVh6OTIn8z6UuvcY282C1A5LtRgpir4wqhIrphd-Mi9gfxra0pJvtydd4XqVpuNdW7GDaC43VXpvUtetmfn-YAo2jkD9G22mUuT2sFdt5NqFL7Rk4tVRILes73OWxfQpuoReWvRBik-sJXxC9ADmTuzR36OvomIrso42R8aufU2ku_zPve8IhYLvn3vHmYCt0zNZkX-jSV8YtGodr9V-dKs9na41YvGp2UxkBcV7LKoGSRELSSNJ8JLF-bjO3zYSSbT42-yeHeKfoWAeP6R7S_0c_AYRA"

      local response, status = http_client.get(STUB_GET_URL, {id = "rs256_user"}, {host = "jwtauth.com", authorization = "Bearer " .. token})
      assert.are.equal(200, status)
    end)

    it("should pass with GET with id in headers", function()
      local key = "example_key"

      local payload = {
          iss = "12345678",
          nbf = os.time(),
          exp = os.time() + 3600,
      }

      local token = jwt.encode(claims, {alg = "HS256", keys = {private = key}})
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "jwtauth.com", authorization = "Bearer " .. token, id = "jwt-auth_tests_consumer"})
      assert.are.equal(200, status)
      local parsed_response = cjson.decode(response)
      assert.are.equal("Bearer " .. token, parsed_response.headers.authorization)
      assert.are.equal("jwt-auth_tests_consumer", parsed_response.headers.id)
    end)

    it("should pass with POST", function()
      local key = "example_key"

      local payload = {
          iss = "12345678",
          nbf = os.time(),
          exp = os.time() + 3600,
      }

      local alg = "HS256"
      local token = jwt.encode(claims, {alg = "HS256", keys = {private = key}})
      local response, status = http_client.post(STUB_POST_URL, {id = "jwt-auth_tests_consumer"}, {host = "jwtauth.com", authorization = "Bearer " .. token})
      assert.are.equal(200, status)
      local parsed_response = cjson.decode(response)
      assert.are.equal("Bearer " .. token, parsed_response.headers.authorization)
    end)

    it("should hide credentials with hide_credentials set", function()
      local key = "example_key"

      local payload = {
          iss = "12345678",
          nbf = os.time(),
          exp = os.time() + 3600,
      }

      local alg = "HS256"
      local token = jwt.encode(claims, {alg = "HS256", keys = {private = key}})
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "jwtauth2.com", authorization = "Bearer " .. token, username = "jwt-auth_tests_consumer"})
      assert.are.equal(200, status)
      local parsed_response = cjson.decode(response)
      assert.are.equal(nil, parsed_response.headers.authorization)
      assert.are.equal(nil, parsed_response.headers.id)
    end)
  end)

  describe("JWT Authentication when secret is base64 encoded", function()

    setup(function()
      spec_helper.prepare_db()
      spec_helper.insert_fixtures {
        api = {
          { name = "tests jwt-auth", inbound_dns = "jwtauth.com", upstream_url = "http://mockbin.com" },
          { name = "tests jwt-auth 2", inbound_dns = "jwtauth2.com", upstream_url = "http://mockbin.com" }
        },
        consumer = {
          { username = "jwt-auth_tests_consumer" }
        },
        plugin = {
          { name = "jwt-auth", config ={ }, __api = 1 },
          { name = "jwt-auth", config ={ id_names = { "username" }, hide_credentials = true }, __api = 2 }
        },
        jwtauth_credential = {
          { secret = "ZXhhbXBsZV9rZXk=", __consumer = 1, secret_is_base64_encoded = true }
        }
      }

      spec_helper.start_kong()
    end)

    teardown(function()
      spec_helper.stop_kong()
    end)

    it("should return 200 success", function()
      local key = "example_key"

      local payload = {
          iss = "12345678",
          nbf = os.time(),
          exp = os.time() + 3600,
      }

      local alg = "HS256"
      local token = jwt.encode(claims, {alg = "HS256", keys = {private = key}})
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "jwtauth2.com", authorization = "Bearer " .. token, username = "jwt-auth_tests_consumer"})
      assert.are.equal(200, status)
      assert.are_not.equal(nil, response)
    end)

    it("should return 403 when signed with different key", function()
      local key = "bad_key"

      local payload = {
          iss = "12345678",
          nbf = os.time(),
          exp = os.time() + 3600,
      }

      local alg = "HS256"
      local token = jwt.encode(claims, {alg = "HS256", keys = {private = key}})
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "jwtauth2.com", authorization = "Bearer " .. token, username = "jwt-auth_tests_consumer"})
      assert.are.equal(401, status)
      assert.are_not.equal(nil, response)
    end)

  end)

  describe("JWT Authentication when secret is not base64 encoded but secret_is_base64_encoded is true ", function()

    setup(function()
      spec_helper.prepare_db()
      spec_helper.insert_fixtures {
        api = {
          { name = "tests jwt-auth", inbound_dns = "jwtauth.com", upstream_url = "http://mockbin.com" },
          { name = "tests jwt-auth 2", inbound_dns = "jwtauth2.com", upstream_url = "http://mockbin.com" }
        },
        consumer = {
          { username = "jwt-auth_tests_consumer" }
        },
        plugin = {
          { name = "jwt-auth", config ={ }, __api = 1 },
          { name = "jwt-auth", config ={ id_names = { "username" }, hide_credentials = true }, __api = 2 }
        },
        jwtauth_credential = {
          { secret = "example_key", __consumer = 1, secret_is_base64_encoded = true }
        }
      }

      spec_helper.start_kong()
    end)

    teardown(function()
      spec_helper.stop_kong()
    end)

    it("should return 403 unauthorized", function()
      local key = "example_key"

      local payload = {
          iss = "12345678",
          nbf = os.time(),
          exp = os.time() + 3600,
      }

      local alg = "HS256"
      local token = jwt.encode(payload, key, alg)
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "jwtauth2.com", authorization = "Bearer " .. token, username = "jwt-auth_tests_consumer"})
      assert.are.equal(401, status)
      assert.are_not.equal(nil, response)
    end)

  end)
end)
