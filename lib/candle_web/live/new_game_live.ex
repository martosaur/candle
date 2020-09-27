defmodule CandleWeb.NewGameLive do
  use CandleWeb, :live_view
  require Logger

  @impl true
  def mount(_params, %{"player" => player}, socket) do
    {:ok, assign(socket, player: player)}
  end

  @impl true
  def handle_event("create", _params, socket) do
    Candle.Game.Server.new(socket.assigns.player)
    |> case do
      {:ok, game_id} -> {:noreply, redirect(socket, to: "/games/#{game_id}")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, "Could not create game")}
    end
  end
end
