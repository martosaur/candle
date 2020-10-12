defmodule CandleWeb.NewGameLive do
  use CandleWeb, :live_view
  require Logger

  @impl true
  def mount(_params, %{"player" => player}, socket) do
    {:ok, assign(socket, player: player)}
  end

  @impl true
  def handle_event("create", %{"game" => %{"name" => name}}, socket) do
    Candle.Game.Server.new(socket.assigns.player, name)
    |> case do
      {:ok, game_id} ->
        try do
          Candle.Game.Server.fetch_package(game_id)
          {:noreply, redirect(socket, to: "/games/#{game_id}")}
        rescue
          _ ->
            {:noreply, put_flash(socket, :error, "Could not fetch package for a game, try again")}
        end

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not create game")}
    end
  end
end
