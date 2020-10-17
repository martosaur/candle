defmodule Candle.Game.State do
  @derive Jason.Encoder
  @enforce_keys [:game_id, :admin]
  defstruct name: "New Game",
            game_id: nil,
            admin: nil,
            players: [],
            lobby: [],
            clients: [],
            package: nil,
            stage: :lobby,
            current_topic: nil,
            current_question: nil,
            active_player_id: nil,
            no_clients_counter: 0

  @stages [:lobby, :starting, :pause, :question, :pending_answer, :results]

  alias Candle.Package.{Topic}
  alias Candle.Game.Player

  def join(state, player, pid) do
    %{state | clients: [{player, pid} | state.clients], no_clients_counter: 0}
    |> update_lobby()
  end

  def client_down(state, pid) do
    %{state | clients: List.keydelete(state.clients, pid, 1)}
    |> update_lobby()
  end

  def update_lobby(%__MODULE__{clients: clients, admin: admin} = state) do
    lobby =
      clients
      |> Enum.map(fn {player, _pid} -> player end)
      |> Enum.uniq_by(fn %{id: id} -> id end)
      |> Enum.reject(fn %{id: id} -> id == admin.id end)

    %{state | lobby: lobby}
  end

  def add_player(state, player_id) do
    player = Enum.find(state.lobby, fn %{id: pid} -> pid == player_id end)

    new_players = [player | state.players] |> Enum.uniq_by(fn %{id: id} -> id end)

    %{state | players: new_players}
  end

  def start_game(%__MODULE__{stage: :lobby} = state) do
    %{state | stage: :starting}
  end

  def remove_player(state, player_id) do
    new_players = Enum.reject(state.players, fn %{id: id} -> id == player_id end)
    %{state | players: new_players}
  end

  # next question
  def next_question(
        %__MODULE__{
          current_topic: %Topic{questions: [current_question | other_questions]}
        } = state
      ) do
    state
    |> Map.put(:current_question, current_question)
    |> Map.update!(:current_topic, fn t -> %{t | questions: other_questions} end)
    |> Map.put(:stage, :question)
  end

  # next topic
  def next_question(
        %__MODULE__{
          package: %Candle.Package{
            topics: [current_topic | other_topics]
          }
        } = state
      ) do
    state
    |> Map.put(:current_topic, current_topic)
    |> Map.update!(:package, fn p -> %{p | topics: other_topics} end)
    |> next_question()
  end

  # out of questions
  def next_question(state) do
    state
    |> Map.put(:current_question, nil)
    |> Map.put(:current_topic, nil)
    |> Map.put(:stage, :results)
  end

  def clap(%__MODULE__{players: players} = state, player_secret) do
    players
    |> Enum.find(nil, fn p -> p.secret == player_secret end)
    |> case do
      nil -> state
      %Player{id: id} -> %{state | active_player_id: id, stage: :pending_answer}
    end
  end

  def answer_correct(
        %__MODULE__{
          players: players,
          active_player_id: player_id,
          current_question: %{reward: reward}
        } = state
      ) do
    updated_players =
      Enum.map(players, fn
        %Player{id: ^player_id} = p -> %{p | score: p.score + reward}
        p -> p
      end)

    state
    |> Map.put(:players, updated_players)
    |> Map.put(:active_player_id, nil)
    |> next_question()
  end

  def answer_incorrect(
        %__MODULE__{
          players: players,
          active_player_id: player_id,
          current_question: %{reward: reward}
        } = state
      ) do
    updated_players =
      Enum.map(players, fn
        %Player{id: ^player_id} = p -> %{p | score: p.score - reward}
        p -> p
      end)

    state
    |> Map.put(:players, updated_players)
    |> Map.put(:active_player_id, nil)
    |> Map.put(:stage, :question)
  end

  def no_answer(state) do
    state
    |> Map.put(:active_player_id, nil)
    |> Map.put(:stage, :question)
  end

  def push_state_to_clients(%__MODULE__{admin: %{id: admin_id}} = state) do
    Enum.map(
      state.clients,
      fn
        {%{id: ^admin_id}, pid} -> GenServer.cast(pid, {:server_update, state, true})
        {_, pid} -> GenServer.cast(pid, {:server_update, state, false})
      end
    )
  end

  def update_counter(%__MODULE__{clients: []} = state) do
    %{state | no_clients_counter: state.no_clients_counter + 1}
  end

  def update_counter(state) do
    %{state | no_clients_counter: 0}
  end
end
