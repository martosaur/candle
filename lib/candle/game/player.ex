defmodule Candle.Game.Player do
  @derive Jason.Encoder
  @enforce_keys [:id, :secret]
  defstruct name: "Anonymous",
            id: nil,
            secret: nil
end
