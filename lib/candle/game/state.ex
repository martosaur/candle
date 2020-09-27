defmodule Candle.Game.State do
  @derive Jason.Encoder
  @enforce_keys [:game_id, :admin]
  defstruct name: "New Game",
            game_id: nil,
            admin: nil,
            players: [],
            lobby: [],
            clients: []

  def join(state, player, pid) do
    %{state | clients: [{player, pid} | state.clients]}
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

  def push_state_to_clients(%__MODULE__{admin: %{id: admin_id}} = state) do
    Enum.map(
      state.clients,
      fn
        {%{id: ^admin_id}, pid} -> GenServer.cast(pid, {:server_update, admin_view(state)})
        {_, pid} -> GenServer.cast(pid, {:server_update, public_view(state)})
      end
    )
  end

  defp public_view(state) do
    state
    |> Map.from_struct()
    |> Map.drop([:clients])
    |> Map.update!(:admin, &Candle.Game.Player.filter_private/1)
    |> Map.update!(:players, fn player ->
      Enum.map(player, &Candle.Game.Player.filter_private/1)
    end)
    |> Map.update!(:lobby, fn player -> Enum.map(player, &Candle.Game.Player.filter_private/1) end)
  end

  defp admin_view(state) do
    public_view(state)
  end
end
