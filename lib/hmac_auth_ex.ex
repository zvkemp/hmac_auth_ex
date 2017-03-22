defmodule HMACAuth do
  require Logger
  def sign(%{ secret: secret, method: method, request_id: request_id, path: path, data: data } = args) do
    timestamp = args[:timestamp] || utc_timestamp()
    data = [method, request_id, path, data, timestamp] |> Enum.join("-")
    Logger.info(data)
    :crypto.hmac(
      :sha,
      secret,
      data
    ) |> Base.encode16(case: :lower)
  end

  def verify(%{ signature: signature } = args) do
    # Welcome, time travellers!
    # In case the clock of the server signing the request is ahead by more than the
    # time it takes to receive the request, we could see failed verifications signatures
    # made around the time the second rolls over. Advance a bit into the future
    # (and compensate in the ttl) to prevent this.
    drift      = args[:drift] || default_drift()
    ttl        = (args[:ttl]  || default_ttl()) + drift
    initial_ts = utc_timestamp()

    result = Stream.iterate(initial_ts + drift, &(&1 - 1))
    |> Enum.take(ttl)
    |> Enum.find(fn (ts) ->
      sign(Map.drop(%{ args | timestamp: ts }, [:signature, :ttl])) == signature
    end)

    case result do
      nil ->
        Logger.warn("UNABLE TO VERIFY ts: #{initial_ts} drift: #{drift} ttl: #{ttl} args: #{inspect(args)}")
        nil
      _ -> result
    end
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
