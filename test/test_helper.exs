Application.put_env(:hmac_auth_ex, :keys, %{ "abcdef" => "abcdef1234567" })
Application.put_env(:plug, :validate_header_keys_during_test, true)
ExUnit.start()
