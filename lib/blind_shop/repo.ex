defmodule BlindShop.Repo do
  use Ecto.Repo,
    otp_app: :blind_shop,
    adapter: Ecto.Adapters.Postgres
end
