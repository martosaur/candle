defmodule CandleWeb.GameLive do
  use CandleWeb, :live_view
  alias Candle.Game.Server
  require Logger

  @impl true
  def mount(%{"id" => game_id}, %{"player" => player}, socket) do
    game_id = String.to_integer(game_id)
    Server.join_game(game_id, player)

    {:ok,
     assign(
       socket,
       game_state: nil,
       player: player,
       is_admin: false
     )}
  end

  @impl true
  def handle_event("add_player", %{"player_id" => player_id}, socket) do
    Server.add_player(
      socket.assigns.game_state.game_id,
      player_id,
      socket.assigns.player
    )

    {:noreply, socket}
  end

  def handle_event("remove_player", %{"player_id" => player_id}, socket) do
    Server.remove_player(
      socket.assigns.game_state.game_id,
      player_id,
      socket.assigns.player
    )

    {:noreply, socket}
  end

  def handle_event("start_game", _, socket) do
    Server.start_game(
      socket.assigns.game_state.game_id,
      socket.assigns.player
    )

    {:noreply, socket}
  end

  def handle_event("next_question", _, socket) do
    Server.next_question(
      socket.assigns.game_state.game_id,
      socket.assigns.player
    )

    {:noreply, socket}
  end

  def handle_event("clap", _, socket) do
    Server.clap(
      socket.assigns.game_state.game_id,
      socket.assigns.player
    )

    {:noreply, socket}
  end

  def handle_event("answer_correct", _, socket) do
    Server.answer_correct(
      socket.assigns.game_state.game_id,
      socket.assigns.player
    )

    {:noreply, socket}
  end

  def handle_event("answer_incorrect", _, socket) do
    Server.answer_incorrect(
      socket.assigns.game_state.game_id,
      socket.assigns.player
    )

    {:noreply, socket}
  end

  def handle_event("no_answer", _, socket) do
    Server.no_answer(
      socket.assigns.game_state.game_id,
      socket.assigns.player
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, redirect(socket, to: "/games/#{socket.assigns.game_state.game_id}")}
  end

  def handle_cast({:server_update, game_state, is_admin}, socket) do
    {:noreply, assign(socket, game_state: game_state, is_admin: is_admin)}
  end
end
