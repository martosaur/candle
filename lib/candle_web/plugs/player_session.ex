defmodule CandleWeb.Plugs.PlayerSession do
  import Plug.Conn

  def init(default), do: default

  def call(
        %Plug.Conn{
          req_cookies: %{
            "_player_secret" => secret,
            "_player_id" => player_id,
            "_player_name" => name
          }
        } = conn,
        _default
      ) do
    player = %Candle.Game.Player{id: player_id, secret: secret, name: name}

    conn
    |> put_session(:player, player)
  end

  def call(conn, _default) do
    player_secret = Base.encode64(:crypto.strong_rand_bytes(32))
    player_id = :rand.uniform(1_000_000) |> to_string()
    player = %Candle.Game.Player{id: player_id, secret: player_secret}

    conn
    |> put_resp_cookie("_player_secret", player.secret)
    |> put_resp_cookie("_player_id", player.id)
    |> put_resp_cookie("_player_name", player.name)
    |> put_session(:player, player)
  end
end
