defmodule Candle.Game.GameNotFoundError do
  defexception [:message, plug_status: 404]
end
