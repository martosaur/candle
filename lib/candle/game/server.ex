defmodule Candle.Game.Server do
  use GenServer

  # Client

  def new(admin_id) do
    game_id = new_game_id()

    GenServer.start(
      __MODULE__,
      %Candle.Game.State{game_id: new_game_id(), admin_id: admin_id},
      name: {:via, Registry, {Candle.GameRegistry, game_id, admin_id}}
    )
    |> case do
      {:ok, _} -> {:ok, game_id}
      error -> error
    end
  end

  def join_game(game_id, player_id) do
    [{pid, _admin_id}] = Registry.lookup(Candle.GameRegistry, game_id)
    new_state = GenServer.call(pid, {:join, player_id})
    Process.monitor(pid)
    new_state
  end

  defp new_game_id() do
    Registry.select(Candle.GameRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:join, player_id}, {pid, _}, state) do
    new_state = Candle.Game.State.join(state, player_id, pid)
    Process.monitor(pid)
    {:reply, new_state, new_state, {:continue, :push_update}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, Candle.Game.State.player_down(state, pid), {:continue, :push_update}}
  end

  @impl true
  def handle_continue(:push_update, state) do
    Candle.Game.State.push_state_to_clients(state)
    {:noreply, state}
  end
end
