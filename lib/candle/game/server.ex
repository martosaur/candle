defmodule Candle.Game.Server do
  use GenServer

  require Logger

  alias Candle.Game.State

  # Client
  def new(admin, "") do
    new(admin, "New Game")
  end

  def new(admin, name) do
    game_id = new_game_id()

    GenServer.start(
      __MODULE__,
      %State{
        game_id: new_game_id(),
        admin: admin,
        name: name,
        package: Candle.Package.get_test_package()
      },
      name: {:via, Registry, {Candle.GameRegistry, game_id}}
    )
    |> case do
      {:ok, _} -> {:ok, game_id}
      error -> error
    end
  end

  def join_game(game_id, player) do
    pid = pid_by_game_id(game_id)
    GenServer.call(pid, {:join, player})
    Process.monitor(pid)
  end

  def add_player(game_id, player_id, actor) do
    pid = pid_by_game_id(game_id)
    GenServer.cast(pid, {:add_player, player_id, actor.secret})
  end

  def remove_player(game_id, player_id, actor) do
    pid = pid_by_game_id(game_id)
    GenServer.cast(pid, {:remove_player, player_id, actor.secret})
  end

  def start_game(game_id, actor) do
    pid = pid_by_game_id(game_id)
    GenServer.cast(pid, {:start_game, actor.secret})
  end

  def next_question(game_id, actor) do
    pid = pid_by_game_id(game_id)
    GenServer.cast(pid, {:next_question, actor.secret})
  end

  def clap(game_id, actor) do
    pid = pid_by_game_id(game_id)
    GenServer.cast(pid, {:clap, actor.secret})
  end

  def answer_correct(game_id, actor) do
    pid = pid_by_game_id(game_id)
    GenServer.cast(pid, {:answer_correct, actor.secret})
  end

  def answer_incorrect(game_id, actor) do
    pid = pid_by_game_id(game_id)
    GenServer.cast(pid, {:answer_incorrect, actor.secret})
  end

  def no_answer(game_id, actor) do
    pid = pid_by_game_id(game_id)
    GenServer.cast(pid, {:no_answer, actor.secret})
  end

  defp new_game_id() do
    Registry.select(Candle.GameRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp pid_by_game_id(game_id) do
    [{pid, _}] = Registry.lookup(Candle.GameRegistry, game_id)
    pid
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:join, player}, {pid, _}, state) do
    new_state = State.join(state, player, pid)
    Process.monitor(pid)
    {:reply, new_state, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_cast(
        {:add_player, player_id, admin_secret},
        %State{admin: %{secret: admin_secret}} = state
      ) do
    new_state = State.add_player(state, player_id)

    {:noreply, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_cast(
        {:remove_player, player_id, admin_secret},
        %State{admin: %{secret: admin_secret}} = state
      ) do
    new_state = State.remove_player(state, player_id)

    {:noreply, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_cast(
        {:start_game, admin_secret},
        %State{stage: :lobby, admin: %{secret: admin_secret}} = state
      ) do
    Process.send_after(self(), {:"$gen_cast", {:next_question, admin_secret}}, 3_000)
    new_state = State.start_game(state)

    {:noreply, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_cast({:next_question, admin_secret}, %State{admin: %{secret: admin_secret}} = state) do
    new_state = State.next_question(state)

    {:noreply, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_cast({:clap, player_secret}, %State{stage: :question} = state) do
    new_state = State.clap(state, player_secret)

    {:noreply, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_cast(
        {:answer_correct, admin_secret},
        %State{stage: :pending_answer, admin: %{secret: admin_secret}} = state
      ) do
    new_state = State.answer_correct(state)

    {:noreply, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_cast(
        {:answer_incorrect, admin_secret},
        %State{stage: :pending_answer, admin: %{secret: admin_secret}} = state
      ) do
    new_state = State.answer_incorrect(state)

    {:noreply, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_cast(
        {:no_answer, admin_secret},
        %State{stage: :pending_answer, admin: %{secret: admin_secret}} = state
      ) do
    new_state = State.no_answer(state)

    {:noreply, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_cast(message, state) do
    Logger.error(
      "Unhandled cast message in Game.Server process: #{inspect(message)}. State: #{
        inspect(state)
      }"
    )

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, State.client_down(state, pid), {:continue, :push_update}}
  end

  @impl true
  def handle_continue(:push_update, state) do
    State.push_state_to_clients(state)
    {:noreply, state}
  end
end
