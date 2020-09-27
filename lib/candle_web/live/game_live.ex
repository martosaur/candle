defmodule CandleWeb.GameLive do
  use CandleWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => game_id}, %{"player" => player}, socket) do
    game_id = String.to_integer(game_id)
    Candle.Game.Server.join_game(game_id, player)

    {:ok,
     assign(
       socket,
       game_state: nil,
       player: player
     )}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, redirect(socket, to: "/games/#{socket.assigns.game_state.game_id}")}
  end

  def handle_cast({:server_update, game_state}, socket) do
    {:noreply, assign(socket, game_state: game_state)}
  end
end
