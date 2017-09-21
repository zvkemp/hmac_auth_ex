defmodule HMACAuth.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  def sign_request(conn, key, secret \\ nil) do
    {:ok, data, _} = Plug.Conn.read_body(conn)
    request_id = "#{key}-#{:crypto.strong_rand_bytes(16) |> Base.encode16}"
    signature = HMACAuth.sign(%{
      secret: secret || Application.get_env(:hmac_auth_ex, :keys)[key], #|> Map.get(key),
      method: conn.method,
      request_id: request_id,
      path: conn.request_path,
      data: data
    })

    conn
    |> put_req_header("x-request-id", request_id)
    |> put_req_header("x-signature", signature)
  end

  def signed_conn(method, path, params_or_body \\ nil) do
    signed_conn(method, path, params_or_body, {"abcdef", nil})
  end

  def signed_conn(method, path, params_or_body, {key, secret}) do
    conn(method, path, params_or_body) |> sign_request(key, secret)
  end

  test "unsigned GET" do
    conn = HMACAuthEx.Plug.call(conn(:get, "/path/to/resource"), [])
    assert conn.private[:hmac_verified] == false
  end

  test "signed GET" do
    conn = HMACAuthEx.Plug.call(signed_conn(:get, "/path/to/resource"), [])
    assert conn.private[:hmac_verified] == true
  end

  test "unsigned POST" do
    conn = HMACAuthEx.Plug.call(conn(:post, "/path/to/resource", %{ data: "foo", metadata: %{ bar: false }}), [])
    assert conn.private[:hmac_verified] == false
  end

  test "signed POST" do
    conn = HMACAuthEx.Plug.call(signed_conn(:post, "/path/to/resource", "{ data: 'foo', metadata: { bar: false }}"), [])
    assert conn.private[:hmac_verified] == true
  end

  test "signed POST, unknown key" do
    bad_creds = {"zyxwv", "thisisabadsecret"}
    conn = HMACAuthEx.Plug.call(signed_conn(:post, "/path/to/resource", "{ data: 'foo', metadata: { bar: false }}", bad_creds), [])
    assert conn.private[:hmac_verified] == false
  end

  test "signed POST, mutated" do
    conn = signed_conn(:post, "/path/to/resource", "{ data: 'foo' }")
    {adapter, meta} = conn.adapter
    meta = Map.put(meta, :req_body, "{ data: 'bar'}")
    conn = %Plug.Conn{ conn | adapter: {adapter, meta}}
    conn = HMACAuthEx.Plug.call(conn, [])
    assert conn.private[:hmac_verified] == false
  end
end
