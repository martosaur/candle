defmodule CandleWeb.NewGameLive do
  use CandleWeb, :live_view
  require Logger

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, session: session)}
  end
end
