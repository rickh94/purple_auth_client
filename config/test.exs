import Config

config :purple_auth_client,
  host: "https://example.com",
  app_id: "123456",
  api_key: "testkey"


config :purple_auth_client, :httpoison, MockHTTPoison
