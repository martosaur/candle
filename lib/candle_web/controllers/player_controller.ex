defmodule CandleWeb.PlayerController do
  use CandleWeb, :controller

  def update(conn, %{"player" => %{"name" => name}}) do
    conn
    |> put_flash(:info, "Name changed")
    |> put_resp_cookie("_player_name", name)
    |> redirect(to: Routes.new_game_path(CandleWeb.Endpoint, :index))
  end
end
