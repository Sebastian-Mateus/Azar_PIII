defmodule ServidorCentral.Repo do
  use Ecto.Repo,
    otp_app: :servidor_central,
    adapter: Ecto.Adapters.Postgres
end
