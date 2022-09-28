# PurpleAuthClient

An Elixir client for my [Purple Auth](https://purpleauth.com) microservice.


## Configuration

```elixir
# config/config.exs
import Config

config :purple_auth_client,
  host: "http://purpleauth.com", # or wherever you're hosting it
  app_id: "[app id obtained from purple auth portal]",
  api_key: "[api key obtained from purple auth portal]"
```

## Routes Covered

### /otp/request/

Start otp authentication flow with server.

```elixir
> PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :otp)
:ok
```

### /magic/request/

```elixir
> PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :magic)
:ok
```

### /otp/confirm/

Complete authentication with email and generated code.

```elixir
> PurpleAuthClient.submit_code("rickhenry@rickhenry.dev", "123456")
{:ok, %{id_token: "tokenfromserver", refresh_token: "refreshtokenfromserver"}}

```

### /token/verify/

Send idToken to server for verification. This is not recommended as local verification will be significantly faster after the first time. 

```elixir
> PurpleAuthClient.verify_token_remote("idtoken")
{:ok, claims}
```

### /token/refresh/

Request a new ID Token from the server using a refresh token

```elixir
> PurpleAuthClient.refresh("refreshtoken")
{:ok, "newidtoken"}
```


## Local Verification

Verify and decode an ID Token on directly in the app without having to
call out every time. It's *much* faster because the keys are cached in an `:ets` table

```elixir
> PurpleAuthClient.verify("idtoken")
{:ok, claims}

> PurpleAuthClient.verify("invalididtoken")
{:error, :signature_error}
```



## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `purple_auth_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:purple_auth_client, "~> 0.1.0"}
  ]
end
```

