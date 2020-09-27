defmodule Candle.Game.Player do
  @derive Jason.Encoder
  @enforce_keys [:id, :secret]
  defstruct name: "Anonymous",
            id: nil,
            secret: nil

  def filter_private(%__MODULE__{} = player) do
    player
    |> Map.put(:secret, nil)
  end
end
