defmodule ServidorCentral.SorteosC do
  @moduledoc """
  Contexto para la gestión de sorteos, premios y la lógica de juego.
  """

  import Ecto.Query

  alias ServidorCentral.{
    Repo,
    Sorteo,
    Premio,
    Billete,
    DetalleCompra,
    Notificacion,
    DetalleNotificacion
  }

  # GESTIÓN DE SORTEOS

  @doc """
  Inicia los servidores de todos los sorteos que están ABIERTOS en la base de datos.
  Se llama al arrancar la aplicación para restaurar el estado.
  """
  def inicializar_servidores_abiertos do
    sorteos_abiertos =
      Sorteo
      |> where([s], s.estado in ["ABIERTO", "PENDIENTE"])
      |> Repo.all()

    Enum.each(sorteos_abiertos, fn s ->
      ServidorCentral.SupervisorSorteos.iniciar_servidor(s.id)
    end)
  end

  @doc """
  Crea un nuevo sorteo. Recibe el id del administrador y los datos del sorteo.
  """
  def crear_sorteo(usuario_id, params) do
    params = Map.put(params, "usuario_id", usuario_id)

    case %Sorteo{}
         |> Sorteo.changeset(params)
         |> Repo.insert() do
      {:ok, sorteo} ->
        ServidorCentral.SupervisorSorteos.iniciar_servidor(sorteo.id)
        {:ok, sorteo}

      error ->
        error
    end
  end

  @doc """
  Lista todos los sorteos ordenados por fecha de juego.
  Precarga los premios asociados a cada sorteo.
  """
  def listar_sorteos do
    Sorteo
    |> order_by([s], s.fecha_juego)
    |> preload(:premios)
    |> Repo.all()
  end

  @doc """
  Lista solo los sorteos abiertos (disponibles para compra).
  """
  def listar_sorteos_abiertos do
    Sorteo
    |> where([s], s.estado == "ABIERTO")
    |> order_by([s], s.fecha_juego)
    |> Repo.all()
  end

  @doc """
  Busca un sorteo por su id.
  """
  def buscar_sorteo(id) do
    case Repo.get(Sorteo, id) do
      nil -> {:error, :no_encontrado}
      sorteo -> {:ok, sorteo}
    end
  end

  @doc """
  Elimina un sorteo. Solo permitido si el sorteo no tiene premios asociados.
  """
  def eliminar_sorteo(id) do
    with {:ok, sorteo} <- buscar_sorteo(id),
         premios <- Repo.all(from(p in Premio, where: p.sorteo_id == ^id)),
         true <- Enum.empty?(premios) do
      Repo.delete(sorteo)
    else
      false -> {:error, :tiene_premios}
      error -> error
    end
  end

  @doc """
  Crea un premio asociado a un sorteo.
  Solo se permite si el sorteo no se ha jugado todavía.
  """
  def crear_premio(sorteo_id, params) do
    with {:ok, sorteo} <- buscar_sorteo(sorteo_id),
         true <- sorteo.estado in ["PENDIENTE", "ABIERTO"] do
      params = Map.put(params, "sorteo_id", sorteo_id)

      %Premio{}
      |> Premio.changeset(params)
      |> Repo.insert()
    else
      false -> {:error, :sorteo_ya_cerrado}
      error -> error
    end
  end

  @doc """
  Lista todos los premios, agrupados por sorteo y ordenados por fecha del sorteo.
  """
  def listar_premios do
    Premio
    |> join(:inner, [p], s in Sorteo, on: p.sorteo_id == s.id)
    |> order_by([p, s], s.fecha_juego)
    |> preload(:sorteo)
    |> Repo.all()
  end

  @doc """
  Elimina un premio. Solo permitido si el sorteo no tiene clientes asociados.
  """
  def eliminar_premio(premio_id) do
    with %Premio{} = premio <- Repo.get(Premio, premio_id),
         false <- tiene_compras?(premio.sorteo_id) do
      Repo.delete(premio)
    else
      nil -> {:error, :no_encontrado}
      true -> {:error, :sorteo_con_compras}
    end
  end

  defp tiene_compras?(sorteo_id) do
    query =
      from(d in DetalleCompra,
        where: d.sorteo_id == ^sorteo_id,
        limit: 1
      )

    Repo.exists?(query)
  end

  # JUGA SORTEOS Y GANADORES

  @doc """
  Actualiza la fecha del sistema y ejecuta todos los sorteos pendientes hasta esa fecha.
  Para cada sorteo que debe jugarse:
    - Genera números ganadores aleatorios para cada premio.
    - Determina ganadores comparando con billetes vendidos.
    - Crea notificaciones para los participantes.
    - Cambia el estado del sorteo a CERRADO.
  """
  def actualizar_fecha_sistema(nueva_fecha) do
    sorteos_a_jugar =
      Sorteo
      |> where([s], s.estado in ["ABIERTO", "PENDIENTE"])
      |> where([s], s.fecha_juego <= ^nueva_fecha)
      |> Repo.all()

    Enum.map(sorteos_a_jugar, fn sorteo -> jugar_sorteo(sorteo) end)
  end

  @doc """
  Ejecuta un sorteo específico: genera ganadores, asigna premios y notifica.
  """
  def jugar_sorteo(sorteo) do
    premios = Repo.all(from(p in Premio, where: p.sorteo_id == ^sorteo.id))

    premios_con_ganador =
      Enum.map(premios, fn premio ->
        numero_ganador = :rand.uniform(sorteo.num_billetes) - 1
        estado = determinar_estado_premio(sorteo.id, numero_ganador)

        {:ok, premio_actualizado} =
          premio
          |> Premio.changeset(%{"numero_ganador" => numero_ganador, "estado" => estado})
          |> Repo.update()

        premio_actualizado
      end)

    {:ok, _sorteo} =
      sorteo
      |> Sorteo.changeset(%{"estado" => "CERRADO"})
      |> Repo.update()

    crear_notificaciones_sorteo(sorteo, premios_con_ganador)

    ServidorCentral.SupervisorSorteos.detener_servidor(sorteo.id)

    {:ok, sorteo, premios_con_ganador}
  end

  defp determinar_estado_premio(sorteo_id, numero_ganador) do
    query =
      from(d in DetalleCompra,
        where: d.sorteo_id == ^sorteo_id and d.numero_billete == ^numero_ganador,
        limit: 1
      )

    if Repo.exists?(query), do: "PENDIENTE", else: "SIN_GANADOR"
  end

  defp crear_notificaciones_sorteo(sorteo, premios) do
    mensaje = construir_mensaje_resultados(sorteo, premios)

    {:ok, notificacion} =
      %Notificacion{}
      |> Notificacion.changeset(%{
        "sorteo_id" => sorteo.id,
        "mensaje" => mensaje,
        "fecha" => Date.utc_today()
      })
      |> Repo.insert()

    participantes = obtener_participantes_sorteo(sorteo.id)

    Enum.each(participantes, fn usuario_id ->
      %DetalleNotificacion{}
      |> DetalleNotificacion.changeset(%{
        "notificacion_id" => notificacion.id,
        "usuario_id" => usuario_id
      })
      |> Repo.insert()
    end)
  end

  defp construir_mensaje_resultados(sorteo, premios) do
    resultados =
      premios
      |> Enum.map(fn p -> "#{p.nombre}: número #{p.numero_ganador}" end)
      |> Enum.join(", ")

    "Sorteo '#{sorteo.nombre}' cerrado. Resultados: #{resultados}"
  end

  defp obtener_participantes_sorteo(sorteo_id) do
    query =
      from(c in ServidorCentral.Compra,
        join: d in DetalleCompra,
        on: d.compra_id == c.id,
        where: d.sorteo_id == ^sorteo_id,
        distinct: c.usuario_id,
        select: c.usuario_id
      )

    Repo.all(query)
  end

  # CONSULTAS Y MÉTRICAS

  @doc """
  Calcula los ingresos totales de un sorteo (suma de todos los subtotales de detalles de compra).
  """
  def consultar_ingresos(sorteo_id) do
    query =
      from(d in DetalleCompra,
        where: d.sorteo_id == ^sorteo_id,
        select: sum(d.subtotal)
      )

    case Repo.one(query) do
      nil -> Decimal.new(0)
      total -> total
    end
  end

  @doc """
  Calcula el balance de un sorteo: ingresos menos premios entregados.
  Solo cuenta premios con estado PENDIENTE o ENTREGADO (los que tuvieron ganador).
  """
  def consultar_balance(sorteo_id) do
    ingresos = consultar_ingresos(sorteo_id)

    query =
      from(p in Premio,
        where: p.sorteo_id == ^sorteo_id and p.estado in ["PENDIENTE", "ENTREGADO"],
        select: sum(p.valor)
      )

    premios_entregados =
      case Repo.one(query) do
        nil -> Decimal.new(0)
        total -> total
      end

    Decimal.sub(ingresos, premios_entregados)
  end

  @doc """
  Lista los clientes que participaron en un sorteo, agrupados por tipo de compra.
  Retorna un mapa con :billete_completo y :fraccion.
  """
  def consultar_clientes_sorteo(sorteo_id) do
    query =
      from(c in ServidorCentral.Compra,
        join: d in DetalleCompra,
        on: d.compra_id == c.id,
        join: u in ServidorCentral.Usuario,
        on: u.id == c.usuario_id,
        join: s in Sorteo,
        on: s.id == d.sorteo_id,
        where: d.sorteo_id == ^sorteo_id,
        select: %{
          usuario: u,
          num_fracciones: d.num_fracciones,
          total_fracciones_sorteo: s.num_fracciones
        },
        order_by: [u.first_lastname, u.first_name]
      )

    registros = Repo.all(query)

    Enum.group_by(registros, fn r ->
      if r.num_fracciones == r.total_fracciones_sorteo, do: :billete_completo, else: :fraccion
    end)
  end

  @doc """
  Consulta el balance global de todos los sorteos cerrados.
  Retorna un mapa con :sorteos (lista con balance individual) y :total_acumulado.
  """
  def consultar_balance_global do
    sorteos_cerrados =
      Sorteo
      |> where([s], s.estado == "CERRADO")
      |> Repo.all()

    detalles =
      Enum.map(sorteos_cerrados, fn s ->
        %{
          sorteo: s,
          ingresos: consultar_ingresos(s.id),
          balance: consultar_balance(s.id)
        }
      end)

    total =
      Enum.reduce(detalles, Decimal.new(0), fn d, acc ->
        Decimal.add(acc, d.balance)
      end)

    %{sorteos: detalles, total_acumulado: total}
  end

  @doc """
  Consulta los premios entregados en sorteos pasados.
  """
  def consultar_premios_entregados do
    query =
      from(p in Premio,
        join: s in Sorteo,
        on: s.id == p.sorteo_id,
        where: s.estado == "CERRADO" and p.estado in ["PENDIENTE", "ENTREGADO"],
        order_by: [s.fecha_juego, p.id],
        preload: [:sorteo]
      )

    Repo.all(query)
  end
end
