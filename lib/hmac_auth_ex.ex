defmodule HMACAuth do
  @spec sign(%{ secret: binary, method: binary, request_id: binary, path: binary, data: binary }) :: binary
  def sign(%{ secret: secret, method: method, request_id: request_id, path: path, data: data } = args) do
    timestamp = args[:timestamp] || utc_timestamp()
    :crypto.hmac(
      :sha,
      secret,
      [method, request_id, path, data, timestamp] |> Enum.join("-")
    ) |> Base.encode16(case: :lower)
  end

  @spec verify(map()) :: integer()
  def verify(%{ signature: signature } = args) do
    # Welcome, time travellers!
    # In case the clock of the server signing the request is ahead by more than the
    # time it takes to receive the request, we could see failed verifications signatures
    # made around the time the second rolls over. Advance a bit into the future
    # (and compensate in the ttl) to prevent this.
    drift = args[:drift] || default_drift()
    ttl   = (args[:ttl] || default_ttl()) + drift

    Stream.iterate(utc_timestamp() + drift, &(&1 - 1))
    |> Enum.take(ttl)
    |> Enum.find(fn (ts) ->
      sign(Map.drop(%{ args | timestamp: ts }, [:signature, :ttl])) == signature
    end)
  end

  @spec utc_timestamp() :: integer()
  def utc_timestamp do
    :os.system_time(:seconds)
  end

  @spec default_drift() :: integer()
  defp default_drift do
    Application.get_env(:hmac_auth_ex, :drift, 5)
  end

  @spec default_ttl() :: integer()
  defp default_ttl do
    Application.get_env(:hmac_auth_ex, :ttl, 5)
  end
end
