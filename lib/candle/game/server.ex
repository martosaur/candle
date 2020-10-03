defmodule Candle.Game.Server do
  use GenServer

  # Client
  def new(admin, "") do
    new(admin, "New Game")
  end

  def new(admin, name) do
    game_id = new_game_id()

    GenServer.start(
      __MODULE__,
      %Candle.Game.State{
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
    GenServer.call(pid, {:add_player, player_id, actor.secret})
  end

  def remove_player(game_id, player_id, actor) do
    pid = pid_by_game_id(game_id)
    GenServer.call(pid, {:remove_player, player_id, actor.secret})
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
    new_state = Candle.Game.State.join(state, player, pid)
    Process.monitor(pid)
    {:reply, new_state, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_call({:add_player, player_id, admin_secret}, _, state) do
    new_state =
      if admin_secret == state.admin.secret do
        Candle.Game.State.add_player(state, player_id)
      else
        state
      end

    {:reply, new_state, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_call({:remove_player, player_id, admin_secret}, _, state) do
    new_state =
      if admin_secret == state.admin.secret do
        Candle.Game.State.remove_player(state, player_id)
      else
        state
      end

    {:reply, new_state, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, Candle.Game.State.client_down(state, pid), {:continue, :push_update}}
  end

  @impl true
  def handle_continue(:push_update, state) do
    Candle.Game.State.push_state_to_clients(state)
    {:noreply, state}
  end
end
