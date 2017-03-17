defmodule HMACAuth do
  def sign(%{ secret: secret, method: method, request_id: request_id, path: path, data: data } = args) do
    timestamp = args[:timestamp] || utc_timestamp()
    :crypto.hmac(
      :sha,
      secret,
      [method, request_id, path, data, timestamp] |> Enum.join("-")
    ) |> Base.encode16(case: :lower)
  end

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

  def utc_timestamp do
    :os.system_time(:seconds)
  end

  defp default_drift do
    Application.get_env(:hmac_auth_ex, :drift, 5)
  end

  defp default_ttl do
    Application.get_env(:hmac_auth_ex, :ttl, 5)
  end
end
