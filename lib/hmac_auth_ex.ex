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
    ttl = args[:ttl] || 3
    Stream.iterate(utc_timestamp, &(&1 - 1))
    |> Enum.take(ttl)
    |> Enum.find(fn (ts) ->
      sign(Map.drop(%{ args | timestamp: ts }, [:signature, :ttl])) == signature
    end)
  end

  def utc_timestamp do
    :os.system_time(:seconds)
  end
end
