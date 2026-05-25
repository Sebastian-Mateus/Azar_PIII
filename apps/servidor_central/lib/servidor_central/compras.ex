defmodule ServidorCentral.Compras do
  @moduledoc """
  Contexto para las operaciones de compra y consulta de jugadores.
  """

  import Ecto.Query
  alias ServidorCentral.{Repo, Sorteo, Billete, Compra, DetalleCompra, Premio}

  # ============================================================
  # COMPRAR
  # ============================================================

  @doc """
  Realiza una compra de fracciones de un billete específico.
  Si el billete no existe en la base de datos, lo crea con todas las fracciones disponibles.
  Valida que el sorteo esté ABIERTO y que haya fracciones suficientes.
  """
  def comprar_fracciones(jugador_id, sorteo_id, numero_billete, cantidad_fracciones) do
    with {:ok, sorteo} <- buscar_sorteo_abierto(sorteo_id),
         :ok <- validar_numero_billete(numero_billete, sorteo),
         {:ok, billete} <- obtener_o_crear_billete(numero_billete, sorteo),
         :ok <- validar_disponibilidad(billete, cantidad_fracciones),
         subtotal <- calcular_subtotal(sorteo, cantidad_fracciones) do
      resultado =
        Repo.transaction(fn ->
          {:ok, compra} =
            %Compra{}
            |> Compra.changeset(%{
              "usuario_id" => jugador_id,
              "fecha" => Date.utc_today(),
              "total" => subtotal
            })
            |> Repo.insert()

          {:ok, _detalle} =
            %DetalleCompra{}
            |> DetalleCompra.changeset(%{
              "sorteo_id" => sorteo_id,
              "numero_billete" => numero_billete,
              "compra_id" => compra.id,
              "num_fracciones" => cantidad_fracciones,
              "subtotal" => subtotal
            })
            |> Repo.insert()

          nuevas_fracciones = billete.fracciones_disponibles - cantidad_fracciones

          {:ok, _billete} =
            billete
            |> Billete.changeset(%{"fracciones_disponibles" => nuevas_fracciones})
            |> Repo.update()

          compra
        end)

      case resultado do
        {:ok, compra} ->
          {:ok,
           %{
             compra_id: compra.id,
             numero: numero_billete,
             cant_fracciones: cantidad_fracciones,
             total: subtotal
           }}

        error ->
          error
      end
    end
  end

  @doc """
  Compra un billete completo, es decir, todas las fracciones del billete.
  """
  def comprar_billete_completo(jugador_id, sorteo_id, numero_billete) do
    case Repo.get(Sorteo, sorteo_id) do
      nil ->
        {:error, :sorteo_no_encontrado}

      sorteo ->
        comprar_fracciones(jugador_id, sorteo_id, numero_billete, sorteo.num_fracciones)
    end
  end

  @doc """
  Consulta cuántas fracciones tiene disponibles un billete específico de un sorteo.
  """
  def consultar_disponibilidad_billete(sorteo_id, numero_billete) do
    case Repo.get(Sorteo, sorteo_id) do
      nil ->
        {:error, :sorteo_no_encontrado}

      sorteo ->
        cond do
          numero_billete < 0 or numero_billete >= sorteo.num_billetes ->
            {:error, :numero_fuera_de_rango}

          true ->
            case Repo.get_by(Billete, numero: numero_billete, sorteo_id: sorteo_id) do
              nil ->
                {:ok,
                 %{
                   numero: numero_billete,
                   fracciones_disponibles: sorteo.num_fracciones,
                   total: sorteo.num_fracciones
                 }}

              billete ->
                {:ok,
                 %{
                   numero: numero_billete,
                   fracciones_disponibles: billete.fracciones_disponibles,
                   total: sorteo.num_fracciones
                 }}
            end
        end
    end
  end

  defp buscar_sorteo_abierto(sorteo_id) do
    case Repo.get(Sorteo, sorteo_id) do
      nil -> {:error, :sorteo_no_encontrado}
      %Sorteo{estado: "ABIERTO"} = sorteo -> {:ok, sorteo}
      _ -> {:error, :sorteo_no_disponible}
    end
  end

  defp validar_numero_billete(numero, sorteo) do
    if numero >= 0 and numero < sorteo.num_billetes do
      :ok
    else
      {:error, :numero_fuera_de_rango}
    end
  end

  defp obtener_o_crear_billete(numero, sorteo) do
    case Repo.get_by(Billete, numero: numero, sorteo_id: sorteo.id) do
      nil ->
        %Billete{}
        |> Billete.changeset(%{
          "numero" => numero,
          "sorteo_id" => sorteo.id,
          "fracciones_disponibles" => sorteo.num_fracciones
        })
        |> Repo.insert()

      billete ->
        {:ok, billete}
    end
  end

  defp validar_disponibilidad(billete, cantidad) do
    if billete.fracciones_disponibles >= cantidad do
      :ok
    else
      {:error, :fracciones_insuficientes}
    end
  end

  defp calcular_subtotal(sorteo, cantidad_fracciones) do
    valor_fraccion = Decimal.div(sorteo.valor_billete, Decimal.new(sorteo.num_fracciones))
    Decimal.mult(valor_fraccion, Decimal.new(cantidad_fracciones))
  end

  # ============================================================
  # DEVOLVER
  # ============================================================

  @doc """
  Devuelve una compra completa.
  Solo permitida si el sorteo aún no ha sido jugado.
  Restituye las fracciones al billete correspondiente.
  """
  def devolver_compra(compra_id) do
    with %Compra{} = compra <- Repo.get(Compra, compra_id),
         detalles <- Repo.all(from(d in DetalleCompra, where: d.compra_id == ^compra_id)),
         :ok <- validar_sorteos_no_jugados(detalles) do
      Repo.transaction(fn ->
        Enum.each(detalles, fn d ->
          billete = Repo.get_by(Billete, numero: d.numero_billete, sorteo_id: d.sorteo_id)
          nuevas_fracciones = billete.fracciones_disponibles + d.num_fracciones

          billete
          |> Billete.changeset(%{"fracciones_disponibles" => nuevas_fracciones})
          |> Repo.update!()

          Repo.delete!(d)
        end)

        Repo.delete!(compra)
        :ok
      end)
    else
      nil -> {:error, :compra_no_encontrada}
      error -> error
    end
  end

  defp validar_sorteos_no_jugados(detalles) do
    sorteo_ids = Enum.map(detalles, & &1.sorteo_id) |> Enum.uniq()

    query =
      from(s in Sorteo,
        where: s.id in ^sorteo_ids and s.estado == "CERRADO",
        limit: 1
      )

    if Repo.exists?(query), do: {:error, :sorteo_ya_cerrado}, else: :ok
  end

  # ============================================================
  # CONSULTAS DEL JUGADOR
  # ============================================================

  @doc """
  Consulta el historial de compras de un jugador con su total gastado.
  """
  def consultar_historial(jugador_id) do
    query =
      from(c in Compra,
        join: d in DetalleCompra,
        on: d.compra_id == c.id,
        join: s in Sorteo,
        on: s.id == d.sorteo_id,
        where: c.usuario_id == ^jugador_id,
        order_by: [desc: c.fecha],
        select: %{
          id: c.id,
          sorteo: s.nombre,
          numero: d.numero_billete,
          num_fracciones: d.num_fracciones,
          total_fracciones: s.num_fracciones,
          valor: d.subtotal,
          fecha: c.fecha
        }
      )

    registros = Repo.all(query)

    compras_adaptadas =
      Enum.map(registros, fn r ->
        tipo =
          if r.num_fracciones == r.total_fracciones, do: "Billete completo", else: "Fracciones"

        %{
          id: r.id,
          sorteo: r.sorteo,
          tipo: tipo,
          numero: r.numero,
          valor: r.valor,
          fecha: r.fecha
        }
      end)

    total = Enum.reduce(registros, Decimal.new(0), fn r, acc -> Decimal.add(acc, r.valor) end)

    %{compras: compras_adaptadas, total_gastado: total}
  end

  @doc """
  Consulta los premios obtenidos por un jugador.
  Recorre las compras del jugador, busca billetes ganadores en sorteos cerrados,
  y calcula el monto proporcional según las fracciones compradas.
  """
  def consultar_premios_obtenidos(jugador_id) do
    query =
      from(d in DetalleCompra,
        join: c in Compra,
        on: c.id == d.compra_id,
        join: p in Premio,
        on: p.sorteo_id == d.sorteo_id and p.numero_ganador == d.numero_billete,
        join: s in Sorteo,
        on: s.id == d.sorteo_id,
        where: c.usuario_id == ^jugador_id and s.estado == "CERRADO",
        select: %{
          sorteo: s.nombre,
          premio: p.nombre,
          valor_premio: p.valor,
          fracciones_compradas: d.num_fracciones,
          total_fracciones: s.num_fracciones
        }
      )

    registros = Repo.all(query)

    Enum.map(registros, fn r ->
      monto_ganado =
        r.valor_premio
        |> Decimal.div(Decimal.new(r.total_fracciones))
        |> Decimal.mult(Decimal.new(r.fracciones_compradas))

      Map.put(r, :monto_ganado, monto_ganado)
    end)
  end

  @doc """
  Consulta el balance personal del jugador: diferencia entre lo gastado y lo ganado.
  """
  def consultar_balance_personal(jugador_id) do
    %{total_gastado: gastado} = consultar_historial(jugador_id)

    ganado =
      jugador_id
      |> consultar_premios_obtenidos()
      |> Enum.reduce(Decimal.new(0), fn p, acc -> Decimal.add(acc, p.monto_ganado) end)

    %{
      total_gastado: gastado,
      total_ganado: ganado,
      balance: Decimal.sub(ganado, gastado)
    }
  end

  @doc """
  Consulta las notificaciones de un jugador a través de sus detalles.
  """
  def consultar_notificaciones(jugador_id) do
    query =
      from(dn in ServidorCentral.DetalleNotificacion,
        join: n in ServidorCentral.Notificacion,
        on: n.id == dn.notificacion_id,
        where: dn.usuario_id == ^jugador_id,
        order_by: [desc: n.fecha],
        select: %{
          id_notificacion: n.id,
          mensaje: n.mensaje,
          fecha: n.fecha,
          estado: dn.estado
        }
      )

    Repo.all(query)
  end

  @doc """
  Marca una notificación como leída para un jugador específico.
  """
  def marcar_notificacion_leida(jugador_id, notificacion_id) do
    case Repo.get_by(ServidorCentral.DetalleNotificacion,
           usuario_id: jugador_id,
           notificacion_id: notificacion_id
         ) do
      nil ->
        {:error, :no_encontrada}

      detalle ->
        detalle
        |> ServidorCentral.DetalleNotificacion.changeset(%{"estado" => "LEIDA"})
        |> Repo.update()
    end
  end

  @doc """
  Consulta los números disponibles (billetes con fracciones disponibles) de un sorteo.
  Retorna mapas con el número y cuántas fracciones tiene disponibles.
  """
  def consultar_numeros_disponibles(sorteo_id) do
    case Repo.get(Sorteo, sorteo_id) do
      nil ->
        {:error, :sorteo_no_encontrado}

      sorteo ->
        billetes_registrados =
          Billete
          |> where([b], b.sorteo_id == ^sorteo_id and b.fracciones_disponibles > 0)
          |> Repo.all()

        billetes_creados_ids = Enum.map(billetes_registrados, & &1.numero)

        # Todos los números posibles del sorteo
        todos = 0..(sorteo.num_billetes - 1)

        # Números nunca comprados (no existen como registros)
        nunca_comprados =
          todos
          |> Enum.reject(fn n ->
            Enum.member?(billetes_creados_ids ++ obtener_ids_agotados(sorteo_id), n)
          end)
          |> Enum.map(fn n ->
            %{numero: n, fracciones_disponibles: sorteo.num_fracciones}
          end)

        # Números con fracciones parciales
        con_fracciones =
          Enum.map(billetes_registrados, fn b ->
            %{numero: b.numero, fracciones_disponibles: b.fracciones_disponibles}
          end)

        {:ok, Enum.sort_by(con_fracciones ++ nunca_comprados, & &1.numero)}
    end
  end

  defp obtener_ids_agotados(sorteo_id) do
    Billete
    |> where([b], b.sorteo_id == ^sorteo_id and b.fracciones_disponibles == 0)
    |> select([b], b.numero)
    |> Repo.all()
  end
end
