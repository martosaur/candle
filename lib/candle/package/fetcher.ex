defmodule Candle.Package.Fetcher do
  def fetch_random_package() do
    page = HTTPoison.get!("https://db.chgk.info/random/from_2010-01-01/answers/types5/limit6")
    page.body
  end
end
