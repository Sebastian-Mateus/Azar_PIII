defmodule ServidorCentral.SupervisorSorteos do
  @moduledoc """
  Supervisor dinámico que gestiona los GenServers de los sorteos activos.
  Permite iniciar y detener servidores de sorteo en tiempo de ejecución.
  """

  use DynamicSupervisor

  alias ServidorCentral.ServidorSorteo

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Inicia un nuevo servidor de sorteo bajo supervisión.
  """
  def iniciar_servidor(sorteo_id) do
    spec = {ServidorSorteo, sorteo_id}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc """
  Detiene el servidor de un sorteo específico.
  """
  def detener_servidor(sorteo_id) do
    case Registry.lookup(ServidorCentral.RegistroSorteos, sorteo_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> {:error, :no_encontrado}
    end
  end

  @doc """
  Lista todos los servidores de sorteo activos.
  """
  def listar_servidores_activos do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
