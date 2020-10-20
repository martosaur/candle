defmodule CandleWeb.PageController do
  use CandleWeb, :controller

  def about(conn, _params) do
    render(conn, "about.html")
  end
end
