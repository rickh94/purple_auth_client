defmodule PurpleAuthClient do
  @moduledoc """
  PurpleAuthClient

  Client library for using my password authentication service Purple Auth, available at
  https://purpleauth.com. Also can be self-hosted. It will handle all the API calls to do
    the authentication

  `PurpleAuthClient` requires configuration values in your application compile environment (`config/config.exs`).

  `:host`: The endpoint where Purple Auth is hosted. Probably `https://purpleauth.com`
  `:app_id`: When you create an app at Purple Auth, it will supply you with an `App ID`. Provide that here.
  `:api_key`: You will also be given an API Key to authorize you and prevent others from using your quota. Be sure not
  to commit this to source control.
  """

  @host Application.compile_env!(:purple_auth_client, :host)
  @app_id Application.compile_env!(:purple_auth_client, :app_id)
  @api_key Application.compile_env!(:purple_auth_client, :api_key)

  @doc """
  Starts authenticating a user by sending information to their `email` using the given `flow`

  ## Parameters
    - email: the email of the user to be authenticated
    - flow: either `:magic` for a magic link the redirects back to your site or `:otp` to send the
    user a code they can enter within a certain time.

  Returns `:ok` or a tuple of `:error` and information about the error

  ## Examples


      > PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :otp)
      :ok

      > PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :magic)
      :ok

      > PurpleAuthClient.start_authentication("bad email", :otp)
      {:error, :validation_error}

  """
  @spec start_authentication(String.t(), :magic | :otp) :: :ok | {:error, any}
  def start_authentication(email, flow)

  def start_authentication(email, :otp) do
    perform_start_authentication(email, "otp")
  end

  def start_authentication(email, :magic) do
    perform_start_authentication(email, "magic")
  end

  @doc """
  Submits the one time password provided by a user. Returns either the new authentication tokens or
  and error and a reason.

  ## Parameters
    - email: The user's email
    - code: code entered by the user based on what they received in their email

  ## Examples

      > PurpleAuthClient.submit_code("rickhenry@rickhenry.dev", "123456")
      {:ok, %{"id_token" => "newjwtidtoken"}}

      > PurpleAuthClient.submit_code("rickhenry@rickhenry.dev", "123457")
      {:error, :authentication_failure}
  """
  @spec submit_code(String.t(), String.t()) ::
          {:error, any} | {:ok, %{:id_token => any, optional(:refresh_token) => any}}
  def submit_code(email, code) do
    with {:ok, data} <- Jason.encode(%{email: email, code: code}),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.post("#{@host}/otp/confirm/#{@app_id}", data, [
             {"Content-Type", "application/json"}
           ]) do
      extract_token(body)
    else
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        check_error(status_code)

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Request the server to do token verification. Returns `:ok` and claims from the token or `:error` and
  a reason.

  ## Parameters
    - id_token: JWT idToken from the client

  ## Examples

      > PurpleAuthClient.verify_token_remote("some_id_token")
      {:ok, %{"sub" => "rickhenry@rickhenry.dev"}}

      > PurpleAuthClient.verify_token_remote("expired_token")
      {:error, :authentication_failure}

  """
  @spec verify_token_remote(String.t()) :: {:error, any} | {:ok, map}
  def verify_token_remote(id_token) do
    with {:ok, data} <- Jason.encode(%{idToken: id_token}),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.post("#{@host}/token/verify/#{@app_id}", data, [
             {"Content-Type", "application/json"}
           ]) do
      extract_token_response(body)
    else
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        check_error(status_code)

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, :unknown_error}
    end
  end

  @doc """
  Request a new ID token using a refresh token. Returns a new id token

  ## Parameters
    - refresh_token: Refresh token from the client.

  ## Examples

      > PurpleAuthClient.refresh("refresh_token")
      {:ok, "newidtokenfromserver"}

      > PurpleAuthClient.refresh("invalid_refresh_token")
      {:error, :authentication_failure}
  """
  @spec refresh(String.t()) :: {:ok, String.t()} | {:error, any}
  def refresh(refresh_token) do
    with {:ok, data} <- Jason.encode(%{refreshToken: refresh_token}),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.post("#{@host}/token/refresh/#{@app_id}", data, [
             {"Content-Type", "application/json"}
           ]),
         {:ok, %{"idToken" => new_id_token, "refreshToken" => _}} <- Jason.decode(body) do
      {:ok, new_id_token}
    else
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        check_error(status_code)

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, :authentication_failure}
    end
  end

  @doc """
  Verify an ID Token locally from your server. This will be *much* faster because we cache the public keys
  so that after the first time, it can be executed without any slow REST API calls. Returns `:ok` and the claims
  from the token or `:error` and information about the error.

  ## Parameters
    - id_token: the token to verify

  ## Examples

      > PurpleAuthClient.verify("useridtoken")
      {:ok, %{"iat" => 123456, "sub" => "rickhenry@rickhenry.dev"}}

      > PurpleAuthClient.verify("fakeuseridtoken")
      {:error, :signature_error}
  """
  @spec verify(String.t()) :: {:ok, map} | {:error, any}
  def verify(id_token) do
    with {:ok, public_key} <- get_public_key(),
         signer <- Joken.Signer.create("ES256", public_key),
         {:ok, %{"exp" => exp, "sub" => _, "iss" => "#{@host}/app/#{@app_id}", "nbf" => nbf } = claims} <- Joken.verify(id_token, signer) do
      cond do
        exp < Joken.current_time() ->
          {:error, :expired_token}
        nbf > Joken.current_time() ->
          {:error, :token_not_yet_valid}
        true ->
            {:ok, claims}
      end
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_token}
    end
  end

  defp perform_start_authentication(email, flow) do
    with {:ok, data} <- Jason.encode(%{email: email}),
         {:ok, %HTTPoison.Response{status_code: 200}} <-
           HTTPoison.post(
             "#{@host}/#{flow}/request/#{@app_id}",
             data,
             [
               {"Content-Type", "application/json"},
               {"Authorization", "Bearer #{@api_key}"}
             ]
           ) do
      :ok
    else
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        check_error(status_code)

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_token(body) do
    with {:ok, %{"idToken" => _} = data} <- Jason.decode(body) do
      {:ok,
       Map.new(data, fn
         {"idToken", idt} -> {:id_token, idt}
         {"refreshToken", rft} -> {:refresh_token, rft}
       end)}
    else
      {:error, _} ->
        {:error, :invalid_response}
    end
  end

  defp extract_token_response(body) do
    with {:ok, %{"headers" => _, "claims" => claims}} <- Jason.decode(body) do
      {:ok, claims}
    else
      _ ->
        {:error, :invalid_token}
    end
  end

  # This function is still kind of ugly, maybe it can be improved somehow?
  defp get_public_key() do
    if :ets.whereis(:purple_auth_cache) == :undefined do
      :ets.new(:purple_auth_cache, [:named_table])
    end

    case :ets.lookup(:purple_auth_cache, :public_key) do
      [{:public_key, key} | _] ->
        {:ok, key}

      _ ->
        case get_public_key_from_server() do
          {:ok, key} ->
            :ets.insert(:purple_auth_cache, {:public_key, key})
            {:ok, key}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp get_public_key_from_server() do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get("#{@host}/app/public_key/#{@app_id}", [
             {"Authorization", "Bearer #{@api_key}"}
           ]),
         {:ok, data} <- Jason.decode(body) do
      {:ok, data}
    else
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        check_error(status_code)

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      _ ->
        {:error, :invalid_response_from_server}
    end
  end

  defp check_error(404), do: {:error, :not_found}
  defp check_error(500), do: {:error, :server_error}
  defp check_error(422), do: {:error, :validation_error}
  defp check_error(401), do: {:error, :authentication_failure}
  defp check_error(403), do: {:error, :authentication_failure}
  defp check_error(_), do: {:error, :unknown_error}
end
