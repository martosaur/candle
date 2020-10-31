defmodule CandleWeb.Plugs.SetLocale do
  import Plug.Conn

  @locales ["en", "ru"]

  def init(default), do: default

  def call(%Plug.Conn{params: %{"locale" => locale}} = conn, _default) when locale in @locales do
    Gettext.put_locale(locale)

    conn
    |> put_session(:locale, locale)
    |> put_resp_cookie("locale", locale)
  end

  def call(%Plug.Conn{req_cookies: %{"locale" => locale}} = conn, _default)
      when locale in @locales do
    Gettext.put_locale(locale)

    conn
    |> put_session(:locale, locale)
  end

  def call(conn, _default) do
    locale = "en"
    Gettext.put_locale(locale)

    conn
    |> put_session(:locale, locale)
    |> put_resp_cookie("locale", locale)
  end
end
