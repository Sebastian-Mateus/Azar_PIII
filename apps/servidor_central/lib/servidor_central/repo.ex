defmodule ServidorCentral.Repo do
  use Ecto.Repo,
    otp_app: :azar_1,
    adapter: Ecto.Adapters.Postgres
end
