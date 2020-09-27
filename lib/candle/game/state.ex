defmodule Candle.Game.State do
  @derive Jason.Encoder
  @enforce_keys [:game_id, :admin_id]
  defstruct name: "New Game",
            game_id: nil,
            admin_id: nil,
            players: [],
            clients: []

  def join(state, player_id, pid) do
    %{state | clients: [{player_id, pid} | state.clients]}
  end

  def player_down(state, pid) do
    %{state | clients: List.keydelete(state.clients, pid, 1)}
  end

  def push_state_to_clients(%__MODULE__{admin_id: admin_id} = state) do
    Enum.map(
      state.clients,
      fn
        {^admin_id, pid} -> GenServer.cast(pid, {:server_update, state})
        {_, pid} -> GenServer.cast(pid, {:server_update, state})
      end
    )
  end
end
