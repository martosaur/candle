defmodule CandleWeb.GameLive do
  use CandleWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => game_id}, %{"player_id" => player_id}, socket) do
    game_id = String.to_integer(game_id)

    {:ok,
     assign(
       socket,
       game_state: Candle.Game.Server.join_game(game_id, player_id),
       player_id: player_id
     )}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, redirect(socket, to: "/games/#{socket.assigns.game_state.game_id}")}
  end

  @impl true
  def handle_cast({:server_update, game_state}, socket) do
    Logger.debug("GOT SERVER UPDATE MESSAGE")
    {:noreply, assign(socket, game_state: game_state)}
  end
end
