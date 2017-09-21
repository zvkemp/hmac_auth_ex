# HMACAuth

Intended to be compatible with the ruby version at http://www.github.com/zvkemp/hmac_auth.

Note:

If used to verify POST requests, the included `HMACAuthEx.Plug` must be used before `Plug.Parsers` (it requires
access to the raw request body, which is removed by json parsing et al).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `hmac_auth_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:hmac_auth_ex, "~> 0.3.0"}]
end
```
  
  2. Add the required config in `config/{env}.exs`:
  
```elixir
  config :hmac_auth_ex, keys: %{key => value}
```

  3. Ensure `hmac_auth_ex` is started before your application:

```elixir
def application do
  [applications: [:hmac_auth_ex]]
end
```

  4. (Optional) If using the plug, add this to your endpoint (usually before the router):
  
```elixir
plug HMACAuthEx.Plug
```

This will add an `hmac_verified: boolean` key to `conn.private`. A basic authentication function might look like this:
```elixir
  defp authenticate(conn, _) do
    cond do
      Mix.env == :dev -> conn # to skip verification in the dev environment
      conn.private.hmac_verified -> conn
      true ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: :signature})
        |> halt
    end
  end
```


