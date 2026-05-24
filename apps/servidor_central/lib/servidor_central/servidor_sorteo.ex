defmodule ServidorCentral.ServidorSorteo do
  @moduledoc """
  Proceso GenServer que gestiona las operaciones de un sorteo específico.
  Cada sorteo activo tiene su propio proceso, garantizando aislamiento y consistencia.
  """

  use GenServer

  alias ServidorCentral.{Compras, SorteosC}

  # ============================================================
  # API PÚBLICA (lo que otros módulos pueden llamar)
  # ============================================================

  @doc """
  Inicia el proceso del servidor de sorteo.
  Se registra en el Registry con el id del sorteo como clave.
  """
  def start_link(sorteo_id) do
    GenServer.start_link(__MODULE__, sorteo_id, name: via_tuple(sorteo_id))
  end

  @doc """
  Solicita la información del sorteo.
  """
  def obtener_info(sorteo_id) do
    GenServer.call(via_tuple(sorteo_id), :obtener_info)
  end

  @doc """
  Solicita la compra de fracciones a través de este servidor.
  """
  def comprar(sorteo_id, jugador_id, numero_billete, cantidad_fracciones) do
    GenServer.call(
      via_tuple(sorteo_id),
      {:comprar, jugador_id, numero_billete, cantidad_fracciones}
    )
  end

  def comprar_completo(sorteo_id, jugador_id, numero_billete) do
    GenServer.call(via_tuple(sorteo_id), {:comprar_completo, jugador_id, numero_billete})
  end

  @doc """
  Solicita la lista de números disponibles del sorteo.
  """
  def consultar_disponibles(sorteo_id) do
    GenServer.call(via_tuple(sorteo_id), :consultar_disponibles)
  end

  @doc """
  Cierra el servidor del sorteo (cuando el sorteo se juega).
  """
  def detener(sorteo_id) do
    GenServer.stop(via_tuple(sorteo_id))
  end

  defp via_tuple(sorteo_id) do
    {:via, Registry, {ServidorCentral.RegistroSorteos, sorteo_id}}
  end

  # ============================================================
  # CALLBACKS DEL GENSERVER (lo que pasa internamente)
  # ============================================================

  @impl true
  def init(sorteo_id) do
    case SorteosC.buscar_sorteo(sorteo_id) do
      {:ok, sorteo} ->
        IO.puts("[ServidorSorteo #{sorteo_id}] Iniciado para sorteo '#{sorteo.nombre}'")
        {:ok, %{sorteo_id: sorteo_id, sorteo: sorteo}}

      {:error, _} ->
        {:stop, :sorteo_no_encontrado}
    end
  end

  @impl true
  def handle_call(:obtener_info, _from, state) do
    {:reply, state.sorteo, state}
  end

  @impl true
  def handle_call({:comprar, jugador_id, numero_billete, cantidad_fracciones}, _from, state) do
    resultado =
      Compras.comprar_fracciones(jugador_id, state.sorteo_id, numero_billete, cantidad_fracciones)

    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:comprar_completo, jugador_id, numero_billete}, _from, state) do
    resultado = Compras.comprar_billete_completo(jugador_id, state.sorteo_id, numero_billete)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call(:consultar_disponibles, _from, state) do
    resultado = Compras.consultar_numeros_disponibles(state.sorteo_id)
    {:reply, resultado, state}
  end

  @impl true
  def terminate(_reason, state) do
    IO.puts("[ServidorSorteo #{state.sorteo_id}] Deteniendo proceso")
    :ok
  end
end
