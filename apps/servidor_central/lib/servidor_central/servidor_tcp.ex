defmodule ServidorCentral.ServidorTCP do
  @moduledoc """
  Servidor TCP que escucha conexiones de las aplicaciones cliente.
  Por cada cliente conectado, levanta un proceso dedicado para atender sus solicitudes.
  """

  use GenServer
  require Logger

  @puerto 4040

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    opciones = [
      :binary,
      packet: 4,
      active: false,
      reuseaddr: true
    ]

    case :gen_tcp.listen(@puerto, opciones) do
      {:ok, socket} ->
        Logger.info("[ServidorTCP] Escuchando en puerto #{@puerto}")
        send(self(), :aceptar)
        {:ok, %{socket: socket}}

      {:error, razon} ->
        Logger.error("[ServidorTCP] No pudo abrir el puerto: #{inspect(razon)}")
        {:stop, razon}
    end
  end

  @impl true
  def handle_info(:aceptar, %{socket: socket} = state) do
    case :gen_tcp.accept(socket) do
      {:ok, cliente_socket} ->
        {:ok, pid} =
          Task.Supervisor.start_child(
            ServidorCentral.SupervisorConexiones,
            fn -> atender_cliente(cliente_socket) end
          )

        :gen_tcp.controlling_process(cliente_socket, pid)
        send(self(), :aceptar)
        {:noreply, state}

      {:error, razon} ->
        Logger.error("[ServidorTCP] Error aceptando conexión: #{inspect(razon)}")
        {:noreply, state}
    end
  end

  defp atender_cliente(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, datos} ->
        solicitud = :erlang.binary_to_term(datos)
        respuesta = procesar_solicitud(solicitud)
        respuesta_binaria = :erlang.term_to_binary(respuesta)
        :gen_tcp.send(socket, respuesta_binaria)
        atender_cliente(socket)

      {:error, :closed} ->
        Logger.info("[ServidorTCP] Cliente desconectado")
        :ok

      {:error, razon} ->
        Logger.error("[ServidorTCP] Error recibiendo: #{inspect(razon)}")
        :ok
    end
  end

  defp procesar_solicitud(solicitud) do
    Logger.info("[ServidorTCP] Solicitud recibida: #{inspect(elem(solicitud, 0))}")

    try do
      ServidorCentral.Despachador.despachar(solicitud)
    rescue
      e ->
        Logger.error("[ServidorTCP] Error procesando solicitud: #{inspect(e)}")
        {:error, :error_interno}
    end
  end
end
