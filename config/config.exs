import Config

config :purple_auth_client, :httpoison, HTTPoison

import_config "#{config_env()}.exs"
