defmodule ServidorCentral.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ServidorCentral.Repo,
      {Registry, keys: :unique, name: ServidorCentral.RegistroSorteos},
      ServidorCentral.SupervisorSorteos,
      {Task.Supervisor, name: ServidorCentral.SupervisorConexiones},
      ServidorCentral.ServidorTCP
      # Starts a worker by calling: ServidorCentral.Worker.start_link(arg)
      # {ServidorCentral.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options

    opts = [strategy: :one_for_one, name: ServidorCentral.Supervisor]
    result = Supervisor.start_link(children, opts)

    ServidorCentral.SorteosC.inicializar_servidores_abiertos()

    result
  end
end
