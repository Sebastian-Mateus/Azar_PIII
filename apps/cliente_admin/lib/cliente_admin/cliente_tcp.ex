defmodule ClienteAdmin.ClienteTCP do
  @moduledoc """
  Cliente TCP para comunicarse con el servidor central.
  Maneja la conexión, envío de solicitudes y recepción de respuestas.
  """

  require Logger

  @host_default ~c"localhost"
  @puerto_default 4040
  @timeout 5000

  @doc """
  Envía una solicitud al servidor y retorna la respuesta.
  Abre una conexión nueva por cada solicitud (modelo simple).

  ## Ejemplos
      enviar({:login, %{email: "x@y.com", password: "abc"}})
      enviar({:listar_sorteos, %{}})
  """
  def enviar(solicitud, opciones \\ []) do
    host = Keyword.get(opciones, :host, @host_default)
    puerto = Keyword.get(opciones, :puerto, @puerto_default)

    opciones_socket = [:binary, packet: 4, active: false]

    case :gen_tcp.connect(host, puerto, opciones_socket, @timeout) do
      {:ok, socket} ->
        resultado = enviar_y_recibir(socket, solicitud)
        :gen_tcp.close(socket)
        resultado

      {:error, razon} ->
        Logger.error("[ClienteTCP] No pudo conectar: #{inspect(razon)}")
        {:error, :sin_conexion}
    end
  end

  defp enviar_y_recibir(socket, solicitud) do
    solicitud_binaria = :erlang.term_to_binary(solicitud)

    case :gen_tcp.send(socket, solicitud_binaria) do
      :ok ->
        case :gen_tcp.recv(socket, 0, @timeout) do
          {:ok, datos} ->
            :erlang.binary_to_term(datos)

          {:error, razon} ->
            Logger.error("[ClienteTCP] Error recibiendo: #{inspect(razon)}")
            {:error, :sin_respuesta}
        end

      {:error, razon} ->
        Logger.error("[ClienteTCP] Error enviando: #{inspect(razon)}")
        {:error, :envio_fallido}
    end
  end

  @doc """
  Configura el host del servidor de forma persistente.
  Útil cuando el cliente debe conectarse a otra máquina en la red.
  """
  def configurar_host(host) do
    Application.put_env(:cliente_admin, :servidor_host, host)
  end

  @doc """
  Obtiene el host configurado actualmente.
  """
  def host_actual do
    Application.get_env(:cliente_admin, :servidor_host, @host_default)
  end
end
