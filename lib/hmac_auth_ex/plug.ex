defmodule HMACAuthEx.Plug do
  import Plug.Conn

  @spec init(any) :: any
  def init(options), do: options

  @spec call(%Plug.Conn{}, any) :: boolean
  def call(conn, _opts) do
    put_private(conn, :hmac_verified, case verify_hmac(conn) do
      :ok -> true
      _ -> false
    end)
  end

  @spec verify_hmac(%Plug.Conn{}) :: :ok | :error
  defp verify_hmac(%Plug.Conn{} = conn) do
    with %{
      "x-signature" => signature,
      "x-request-id" => request_id
    }              <- Enum.into(conn.req_headers, %{}),
    [key|_]        <- String.split(request_id, "-"),
    {:ok, body, _} <- Plug.Conn.read_body(conn)
    do
      verify_hmac({conn, key, signature, request_id, body})
    else
      _ -> :error
    end
  end

  @spec verify_hmac({%Plug.Conn{}, binary, binary, binary, binary}) :: :ok | :error
  defp verify_hmac({conn, key, signature, request_id, body}) when is_binary(signature) do
    verify_hmac_with_secret({conn, hmac_secret(key), signature, request_id, body})
  end

  defp verify_hmac(_), do: :error

  defp verify_hmac_with_secret({conn, secret, signature, request_id, body}) when is_binary(secret) do
    cond do
      HMACAuth.verify(%{
        path: conn.request_path,
        secret: secret,
        method: conn.method,
        request_id: request_id,
        signature: signature,
        data: body,
        timestamp: nil,
        ttl: Application.get_env(:hmac_auth_ex, :ttl, 3)
      }) -> :ok
      true -> :error
    end
  end

  defp verify_hmac_with_secret(_), do: :error # no valid secret was found

  @spec hmac_secret(binary) :: binary | :error
  defp hmac_secret(key) do
    with %{^key => secret} <- Application.get_env(:hmac_auth_ex, :keys) do
      secret
    else
      _ -> :error
    end
  end
end
