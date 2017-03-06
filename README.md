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
      [{:hmac_auth_ex, "~> 0.1.0"}]
    end
    ```

  2. Ensure `hmac_auth_ex` is started before your application:

    ```elixir
    def application do
      [applications: [:hmac_auth_ex]]
    end
    ```

