defmodule BlindShopWeb.Plugs.RawBody do
  @moduledoc """
  Plug to capture the raw request body for Stripe webhook verification
  """

  def init(opts), do: opts

  def call(conn, _opts) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} ->
        Plug.Conn.assign(conn, :raw_body, body)
        
      {:more, _partial_body, conn} ->
        # For very large bodies, read in chunks
        read_body_chunks(conn, "")
        
      {:error, _reason} = error ->
        conn
        |> Plug.Conn.send_resp(400, "Bad Request")
        |> Plug.Conn.halt()
    end
  end

  defp read_body_chunks(conn, acc) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} ->
        full_body = acc <> body
        Plug.Conn.assign(conn, :raw_body, full_body)
        
      {:more, body, conn} ->
        read_body_chunks(conn, acc <> body)
        
      {:error, _reason} ->
        conn
        |> Plug.Conn.send_resp(400, "Bad Request")
        |> Plug.Conn.halt()
    end
  end
end