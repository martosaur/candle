defmodule CandleWeb.GameLive do
  use CandleWeb, :live_view
  alias Candle.Game.Server
  require Logger

  @impl true
  def mount(%{"id" => game_id}, %{"player" => player, "locale" => locale}, socket) do
    Gettext.put_locale(locale)

    game_id = String.to_integer(game_id)
    Server.join_game(game_id, player)

    {:ok,
     assign(
       socket,
       game_state: nil,
       player: player,
       is_admin: false,
       custom_package: nil
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

  def handle_event(
        "change_answer",
        %{
          "player_id" => player_id,
          "topic_name" => topic_name,
          "question_reward" => question_reward,
          "new_answer" => new_answer
        },
        socket
      ) do
    new_answer =
      case new_answer do
        "true" -> true
        "false" -> false
        _ -> nil
      end

    question_reward = String.to_integer(question_reward)

    Server.change_answer(
      socket.assigns.game_state.game_id,
      player_id,
      topic_name,
      question_reward,
      new_answer,
      socket.assigns.player
    )

    {:noreply, socket}
  end

  def handle_event("fetch_random_package", _, socket) do
    Server.fetch_random_package(
      socket.assigns.game_state.game_id,
      socket.assigns.player
    )

    {:noreply, assign(socket, custom_package: nil)}
  end

  def handle_event("custom_package_start", _, socket) do
    {:noreply, assign(socket, custom_package: :in_progress)}
  end

  def handle_event("custom_package_cancel", _, socket) do
    {:noreply, assign(socket, custom_package: nil)}
  end

  def handle_event(
        "create_custom_package",
        %{"custom_package" => %{"number_of_topics" => topics}},
        socket
      ) do
    case Integer.parse(topics) do
      {number, ""} ->
        Server.fetch_empty_package(
          socket.assigns.game_state.game_id,
          number,
          socket.assigns.player
        )

        {:noreply, assign(socket, custom_package: nil)}

      _ ->
        {:noreply, put_flash(socket, :error, gettext("Number of topics is not a number"))}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply,
     redirect(socket,
       to: Routes.game_path(CandleWeb.Endpoint, :show, socket.assigns.game_state.game_id)
     )}
  end

  def handle_cast({:server_update, game_state, is_admin}, socket) do
    {:noreply, assign(socket, game_state: game_state, is_admin: is_admin)}
  end
end
