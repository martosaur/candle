defmodule CandleWeb.NewGameLive do
  use CandleWeb, :live_view
  require Logger

  @impl true
  def mount(_params, %{"player" => player, "locale" => locale}, socket) do
    Gettext.put_locale(locale)
    {:ok, assign(socket, player: player)}
  end

  @impl true
  def handle_event("create", %{"game" => %{"name" => name}}, socket) do
    Candle.Game.Server.new(socket.assigns.player, name)
    |> case do
      {:ok, game_id} ->
        Candle.Game.Server.set_locale(game_id, Gettext.get_locale())
        {:noreply, redirect(socket, to: Routes.game_path(CandleWeb.Endpoint, :show, game_id))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not create game")}
    end
  end
end
