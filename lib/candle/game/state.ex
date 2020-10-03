defmodule Candle.Game.State do
  @derive Jason.Encoder
  @enforce_keys [:game_id, :admin]
  defstruct name: "New Game",
            game_id: nil,
            admin: nil,
            players: [],
            lobby: [],
            clients: [],
            package: nil

  alias Candle.Game.Player

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

  def add_player(state, player_id) do
    player = Enum.find(state.lobby, fn %{id: pid} -> pid == player_id end)

    new_players =
      [Player.filter_private(player) | state.players] |> Enum.uniq_by(fn %{id: id} -> id end)

    %{state | players: new_players}
  end

  def remove_player(state, player_id) do
    new_players = Enum.reject(state.players, fn %{id: id} -> id == player_id end)
    %{state | players: new_players}
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
    |> Map.put(:clients, [])
    |> Map.update!(:admin, &Player.filter_private/1)
    |> Map.update!(:players, fn players ->
      Enum.map(players, &Player.filter_private/1)
    end)
    |> Map.update!(:lobby, fn players ->
      Enum.map(players, &Player.filter_private/1)
    end)
  end

  defp admin_view(state) do
    public_view(state)
  end
end
