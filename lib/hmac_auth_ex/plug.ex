defmodule HMACAuthEx.Plug do
  import Plug.Conn
  require Logger

  def init(options), do: options

  def call(conn, _opts) do
    put_private(conn, :hmac_verified, case verify_hmac(conn) do
      :ok -> true
      _   -> false
    end)
  end

  defp verify_hmac(conn) do
    with %{
      "x-signature" => signature,
      "x-request-id" => request_id
    } <- Enum.into(conn.req_headers, %{}),
    {:ok, body, _} <- Plug.Conn.read_body(conn)
    do
      [key|_] = String.split(request_id, "-")
      HMACAuth.verify(%{
        path: conn.request_path,
        secret: hmac_secret(key),
        method: conn.method,
        request_id: request_id,
        signature: signature,
        data: body,
        timestamp: nil,
        ttl: Application.get_env(:hmac_auth_ex, :ttl, 3)
      }) && :ok || :error
    else
      _ -> :error
    end
  end

  defp hmac_secret(key) do
    with %{^key => secret} <- Application.get_env(:hmac_auth_ex, :keys), do: secret
  end
end
