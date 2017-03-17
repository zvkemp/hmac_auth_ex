defmodule HMACAuthTest do
  use ExUnit.Case
  doctest HMACAuth

  setup do
    digestables = %{
      path: "/foo/bar",
      secret: "drat said toad",
      method: "GET",
      data: "",
      timestamp: nil,
      request_id: "abcdef123456"
    }

    { :ok, %{ digestables: digestables } }
  end

  test "matches equivalent signature on the ruby version", %{ digestables: digestables } do
    assert HMACAuth.sign(%{ digestables | timestamp: 1470421192 }) == "b3727df1b9e82fa64ef6d62d7721e64764edd633"
  end

  test "timestamp not provided", %{ digestables: digestables } do
    assert HMACAuth.sign(digestables) != "b3727df1b9e82fa64ef6d62d7721e64764edd633"
  end

  test "sign and verify", %{ digestables: digestables } do
    signature = HMACAuth.sign(digestables)
    assert HMACAuth.verify(Map.merge(digestables, %{ signature: signature }))
  end

  test "expired ttl", %{ digestables: digestables } do
    ts = HMACAuth.utc_timestamp - 15
    signature = HMACAuth.sign(%{ digestables | timestamp: ts })
    refute HMACAuth.verify(Map.merge(digestables, %{ signature: signature }))
  end

  test "extended ttl", %{ digestables: digestables } do
    ts = HMACAuth.utc_timestamp - 15
    signature = HMACAuth.sign(%{ digestables | timestamp: ts })
    assert HMACAuth.verify(Map.merge(digestables, %{ signature: signature, ttl: 20 }))
  end

  test "with server time drift", %{ digestables: digestables } do
    ts = HMACAuth.utc_timestamp + 3
    signature = HMACAuth.sign(%{ digestables | timestamp: ts })
    assert HMACAuth.verify(Map.merge(digestables, %{ signature: signature, ttl: 20 }))
  end

  test "with server time drift outside the verification range", %{ digestables: digestables } do
    ts = HMACAuth.utc_timestamp + 3
    signature = HMACAuth.sign(%{ digestables | timestamp: ts })
    refute  HMACAuth.verify(Map.merge(digestables, %{ drift: 1, signature: signature, ttl: 20 }))
  end
end
