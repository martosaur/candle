defmodule CandleWeb.Plugs.PlayerId do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{req_cookies: %{"_player_session_id" => psid}} = conn, _default) do
    conn
    |> put_session(:player_id, psid)
  end

  def call(conn, _default) do
    session_id = Base.encode64(:crypto.strong_rand_bytes(32))

    conn
    |> put_resp_cookie("_player_session_id", session_id)
    |> put_session(:player_id, session_id)
  end
end
