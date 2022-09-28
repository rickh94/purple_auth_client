defmodule PurpleAuthClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup do
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes")
    :ok
  end

  describe "test start_authentication/2 otp" do
    test "calls api to start otp authentication" do
      use_cassette "start_otp_authentication_success" do
        assert :ok == PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :otp)
      end
    end

    test "gives error if start_authentication otp is unauthorized" do
      use_cassette "start_otp_authentication_fail_unauthorized" do
        assert {:error, :authentication_failure} ==
                 PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :otp)
      end
    end

    test "start_authentication otp gives error if app is not found" do
      use_cassette "start_otp_authentication_fail_not_found" do
        assert {:error, :not_found} ==
                 PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :otp)
      end
    end

    test "start_authentication otp gives error if server returns error" do
      use_cassette "start_otp_authentication_fail_server_error" do
        assert {:error, :server_error} ==
                 PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :otp)
      end
    end

    test "start_authentication otp gives error if body does not validate" do
      use_cassette "start_otp_authentication_fail_validation_error" do
        assert {:error, :validation_error} ==
                 PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :otp)
      end
    end
  end

  describe "start_authentication/2 magic" do
    test "calls api to start magic authentication" do
      use_cassette "start_magic_authentication_success" do
        assert :ok = PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :magic)
      end
    end

    test "gives error if start_authentication magic is unauthorized" do
      use_cassette "start_magic_authentication_fail_unauthorized" do
        assert {:error, :authentication_failure} ==
                 PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :magic)
      end
    end

    test "start_authentication magic gives error if app is not found" do
      use_cassette "start_magic_authentication_fail_not_found" do
        assert {:error, :not_found} =
                 PurpleAuthClient.start_authentication("rickhenry@rickhenry.dev", :magic)
      end
    end
  end

  describe "submit_code/2" do
    test "submit_code success" do
      use_cassette "submit_code_success" do
        {:ok, %{id_token: idt, refresh_token: rft}} =
          PurpleAuthClient.submit_code("rickhenry@rickhenry.dev", "773642")

        assert String.length(idt) > 0
        assert String.length(rft) > 0
      end
    end

    test "submit_code failure" do
      use_cassette "submit_code_failure_wrong_code" do
        {:error, reason} = PurpleAuthClient.submit_code("rickhenry@rickhenry.dev", "123456")
        assert reason == :authentication_failure
      end
    end

    test "submit_code not found" do
      use_cassette "submit_code_failure_not_found" do
        assert {:error, :not_found} =
                 PurpleAuthClient.submit_code("rickhenry@rickhenry.dev", "123456")
      end
    end
  end

  describe "verify_token_remote/1" do
    test "verify_token_remote succeeds with valid token" do
      use_cassette "verify_token_remote_successful" do
        {:ok, claims} =
          PurpleAuthClient.verify_token_remote(
            "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjM3OTk2NjYsImlhdCI6MTY2Mzc5NjA2NiwiaXNzIjoiaHR0cHM6Ly9wdXJwbGVhdXRoLmNvbS9hcHAvZWIxYzQyMjUtYzc2Zi00ZWVlLWFjZmQtYmIwNzhmODM0ZTdmIiwianRpIjoiZUlDdUN2elNNSWFGOFdHLS1lT2dRdyIsIm5iZiI6MTY2Mzc5NjA2Niwic3ViIjoicmlja2hlbnJ5QHJpY2toZW5yeS5kZXYifQ.k77ajj46uOkO-Vco_PNE8B09hTriPgvIm5R2lGEnSx0zvSjoeeLvxNWJ48P5JfxYBQjqZoTZcdIWimBpr-BmTw"
          )

        assert claims["sub"] == "rickhenry@rickhenry.dev"
        assert claims["iss"] == "https://purpleauth.com/app/eb1c4225-c76f-4eee-acfd-bb078f834e7f"
      end
    end

    test "verify_token_remote fails with invalid token" do
      use_cassette "verify_token_remote_fails_invalid_token" do
        {:error, :authentication_failure} ==
          PurpleAuthClient.verify_token_remote(
            "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjM3NDE5MDAsImlhdCI6MTY2MzczODMwMCwiaXNzIjoiaHR0cHM6Ly9wdXJwbGVhdXRoLmNvbS9hcHAvZWIxYzQyMjUtYzc2Zi00ZWVlLWFjZmQtYmIwNzhmODM0ZTdmIiwianRpIjoiSTBHOXdqcEt0ZllIc3R2WmdoaWE5QSIsIm5iZiI6MTY2MzczODMwMCwic3ViIjoicmlja2hlbnJ5QHJpY2toZW5yeS5kZXYifQ.h2QF__wPH4nVsPyd0v6kcIi8sJWDkG1xByb5gdEYGoJN6Ok7UIbqwRRfZX0uySerUR2vy1sH9Kxpy_geZOREdQ"
          )
      end
    end

    test "verify_token_remote fails not_found" do
      use_cassette "verify_token_remote_fails_not_found" do
        assert {:error, :not_found} = PurpleAuthClient.verify_token_remote("123")
      end
    end
  end

  describe "refresh/1" do
    test "refresh succeeds with valid token" do
      use_cassette "refresh_successful" do
        {:ok, new_token} =
          PurpleAuthClient.refresh(
            "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NjM4ODI0NjYsImlhdCI6MTY2Mzc5NjA2NiwiaXNzIjoiaHR0cHM6Ly9wdXJwbGVhdXRoLmNvbS9hcHAvZWIxYzQyMjUtYzc2Zi00ZWVlLWFjZmQtYmIwNzhmODM0ZTdmIiwianRpIjoiU1FNcUFuTmZwTXZVSDB3SWg0d0VsQSIsIm5iZiI6MTY2Mzc5NjA2Niwic3ViIjoicmlja2hlbnJ5QHJpY2toZW5yeS5kZXYiLCJ1aWQiOiJiMWFiNmFhMS1lNWU5LTRlYTgtOTIyZC0xMTBmYjA0N2ZiZWEifQ.8_YaDT8Bab65YERavy7pGCkqdynVrk0geaksoFNvdkFRrIRKJ8COJdkGk-MOIzndTHGIvXb4Z2s8ciKGJckXvA"
          )

        assert String.length(new_token) > 50
      end
    end

    test "refresh fails with invalid token" do
      use_cassette "refresh_fail" do
        assert {:error, :authentication_failure} == PurpleAuthClient.refresh("12345678")
      end
    end

    test "refresh fails with app not found" do
      use_cassette "refresh_fail_not_found" do
        assert {:error, :not_found} == PurpleAuthClient.refresh("12345678")
      end
    end
  end

  describe "verify/1" do
    @fake_signer Joken.Signer.create("ES256", %{
                   "crv" => "P-256",
                   "d" => "JKD9SOKKPo_mhQAOFQVsyD_6P_nZXcrtDAWABFyHrBA",
                   "kty" => "EC",
                   "size" => 2048,
                   "x" => "2MwBwaaAxky_9mrqFe4XYm9avA8PYhxcYsLNq5A2tBo",
                   "y" => "1na1PLoZgmwjXYlsI_kJqs7FxBXj1Tvc9pCUX7qc5Zw"
                 })

    @valid_claims %{
      "exp" => Joken.current_time() + 3600,
      "iat" => Joken.current_time() - 10,
      "iss" => "https://purpleauth.com/app/eb1c4225-c76f-4eee-acfd-bb078f834e7f",
      "jti" => Joken.generate_jti(),
      "nbf" => Joken.current_time() - 10,
      "sub" => "rickhenry@rickhenry.dev"
    }

    test "valid token succeeds" do
      {:ok, jwt, _claims} = Joken.encode_and_sign(@valid_claims, @fake_signer)

      use_cassette "get public jwks from server" do
        {:ok, claims_out} = PurpleAuthClient.verify(jwt)

        for {k, v} <- @valid_claims do
          assert v == claims_out[k]
        end
      end
    end

    test "failure to get keys returns error" do
      {:ok, jwt, _claims} = Joken.encode_and_sign(@valid_claims, @fake_signer)

      use_cassette "get_public_jwks_from_server_not_found" do
        assert {:error, :not_found} == PurpleAuthClient.verify(jwt)
      end
    end

    test "gets cached keys from :ets" do
      :ets.new(:purple_auth_cache, [:named_table])

      :ets.insert(
        :purple_auth_cache,
        {:public_key,
         %{
           "crv" => "P-256",
           "kty" => "EC",
           "x" => "2MwBwaaAxky_9mrqFe4XYm9avA8PYhxcYsLNq5A2tBo",
           "y" => "1na1PLoZgmwjXYlsI_kJqs7FxBXj1Tvc9pCUX7qc5Zw"
         }}
      )
      {:ok, jwt, _} = Joken.encode_and_sign(@valid_claims, @fake_signer)

      # This cassette will ensure that if it tries to get the keys by making an http request, it won't
      # get them, therefore it must have pulled the keys we saved in the cache above.
      use_cassette "get_public_jwks_from_server_not_found" do
        {:ok, claims_out} = PurpleAuthClient.verify(jwt)

        for {k, v} <- @valid_claims do
          assert v == claims_out[k]
        end
      end
    end

    test "verify token fails with expired token" do
      claims_in =
        @valid_claims
        |> Map.new(fn
          {"exp", exp} -> {"exp", exp - 3700}
          {"iat", iat} -> {"iat", iat - 3600}
          {"nbf", nbf} -> {"nbf", nbf - 3600}
          {k, v} -> {k, v}
        end)

      {:ok, jwt, _claims} = Joken.encode_and_sign(claims_in, @fake_signer)

      use_cassette "get public jwks from server" do
        assert {:error, :expired_token} == PurpleAuthClient.verify(jwt)
      end
    end

    test "verify token fails with not yet valid token" do
      claims_in =
        @valid_claims
        |> Map.new(fn
          {"nbf", nbf} -> {"nbf", nbf + 200}
          {"iat", iat} -> {"iat", iat + 200}
          {k, v} -> {k, v}
        end)

      {:ok, jwt, _claims} = Joken.encode_and_sign(claims_in, @fake_signer)

      use_cassette "get public jwks from server" do
        assert {:error, :token_not_yet_valid} == PurpleAuthClient.verify(jwt)
      end
    end

    test "verify token fails with wrong keys" do
      invalid_signer =
        Joken.Signer.create("ES256", %{
          "crv" => "P-256",
          "d" => "h0IgGB16VmC7rJmhG-Tt2R81z33ebs9mJzE6mb34Bl0",
          "kty" => "EC",
          "size" => 2048,
          "x" => "dzLcWQ2AccjtGP78o-4envB9iy6Q3KWbOLe7yH42UNU",
          "y" => "F1SJ2wHE6hg4H9qoyTtAMa4WwXmI_64uAZgUdGt9BaE"
        })

      {:ok, jwt, _claims} = Joken.encode_and_sign(@valid_claims, invalid_signer)

      use_cassette "get public jwks from server" do
        {:error, :signature_error} = PurpleAuthClient.verify(jwt)
      end
    end

    test "verify token fails with wrong issuer" do
      claims_in =
        @valid_claims
        |> Map.new(fn
          {"iss", _} -> {"iss", "https://example.com"}
          {k, v} -> {k, v}
        end)

      {:ok, jwt, _claims} = Joken.encode_and_sign(claims_in, @fake_signer)

      use_cassette "get public jwks from server" do
        {:error, :invalid_token} = PurpleAuthClient.verify(jwt)
      end
    end
  end
end
