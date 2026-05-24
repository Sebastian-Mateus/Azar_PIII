defmodule ServidorCentral.Despachador do
  @moduledoc """
  Enruta las solicitudes recibidas por TCP a los contextos correspondientes
  y adapta las respuestas al formato que esperan los clientes.
  """

  alias ServidorCentral.{Cuentas, SorteosC, Compras, ServidorSorteo}

  # ============================================================
  # CUENTAS
  # ============================================================

  def despachar({:registrar_usuario, params}) do
    case Cuentas.registrar_usuario(params) do
      {:ok, usuario} -> {:ok, serializar_usuario(usuario)}
      error -> error
    end
  end

  def despachar({:login, %{email: email, password: password}}) do
    case Cuentas.login(email, password) do
      {:ok, usuario} -> {:ok, serializar_usuario(usuario)}
      error -> error
    end
  end

  def despachar({:listar_usuarios, _}) do
    {:ok, Enum.map(Cuentas.listar_usuarios(), &serializar_usuario/1)}
  end

  def despachar({:listar_por_rol, %{rol: rol}}) do
    {:ok, Enum.map(Cuentas.listar_por_rol(rol), &serializar_usuario/1)}
  end

  # ============================================================
  # SORTEOS
  # ============================================================

  def despachar({:crear_sorteo, %{usuario_id: usuario_id, datos: datos}}) do
    case SorteosC.crear_sorteo(usuario_id, datos) do
      {:ok, sorteo} -> {:ok, serializar_sorteo(sorteo)}
      error -> error
    end
  end

  def despachar({:listar_sorteos, _}) do
    {:ok, Enum.map(SorteosC.listar_sorteos(), &serializar_sorteo/1)}
  end

  def despachar({:listar_sorteos_abiertos, _}) do
    {:ok, Enum.map(SorteosC.listar_sorteos_abiertos(), &serializar_sorteo/1)}
  end

  def despachar({:eliminar_sorteo, %{id: id}}) do
    SorteosC.eliminar_sorteo(id)
  end

  def despachar({:crear_premio, %{sorteo_id: sorteo_id, datos: datos}}) do
    case SorteosC.crear_premio(sorteo_id, datos) do
      {:ok, premio} -> {:ok, serializar_premio(premio)}
      error -> error
    end
  end

  def despachar({:listar_premios, _}) do
    {:ok, premios_agrupados_por_sorteo()}
  end

  def despachar({:eliminar_premio, %{id: id}}) do
    SorteosC.eliminar_premio(id)
  end

  def despachar({:actualizar_fecha, %{fecha: fecha}}) do
    {:ok, SorteosC.actualizar_fecha_sistema(fecha)}
  end

  def despachar({:consultar_ingresos, %{sorteo_id: id}}) do
    {:ok, SorteosC.consultar_ingresos(id)}
  end

  def despachar({:consultar_balance, %{sorteo_id: id}}) do
    {:ok, SorteosC.consultar_balance(id)}
  end

  def despachar({:consultar_clientes_sorteo, %{sorteo_id: id}}) do
    {:ok, formatear_clientes(SorteosC.consultar_clientes_sorteo(id))}
  end

  def despachar({:consultar_balance_global, _}) do
    {:ok, formatear_balance_global(SorteosC.consultar_balance_global())}
  end

  def despachar({:consultar_premios_entregados, _}) do
    {:ok, formatear_premios_entregados()}
  end

  # ============================================================
  # COMPRAS
  # ============================================================

  def despachar({:comprar_fracciones, %{jugador_id: j, sorteo_id: s, numero: n, cantidad: c}}) do
    ServidorSorteo.comprar(s, j, n, c)
  end

  def despachar({:comprar_billete_completo, %{jugador_id: j, sorteo_id: s, numero_billete: n}}) do
    ServidorSorteo.comprar_completo(s, j, n)
  end

  def despachar({:consultar_disponibles, %{sorteo_id: s}}) do
    ServidorSorteo.consultar_disponibles(s)
  end

  def despachar({:consultar_disponibilidad_billete, %{sorteo_id: s, numero: n}}) do
    Compras.consultar_disponibilidad_billete(s, n)
  end

  def despachar({:devolver_compra, %{compra_id: id}}) do
    Compras.devolver_compra(id)
  end

  def despachar({:consultar_historial, %{jugador_id: id}}) do
    {:ok, Compras.consultar_historial(id)}
  end

  def despachar({:consultar_premios_obtenidos, %{jugador_id: id}}) do
    {:ok, Compras.consultar_premios_obtenidos(id)}
  end

  def despachar({:consultar_balance_personal, %{jugador_id: id}}) do
    {:ok, Compras.consultar_balance_personal(id)}
  end

  def despachar({:consultar_notificaciones, %{jugador_id: id}}) do
    {:ok, Compras.consultar_notificaciones(id)}
  end

  def despachar({:marcar_notificacion_leida, %{jugador_id: j, notificacion_id: n}}) do
    Compras.marcar_notificacion_leida(j, n)
  end

  # ============================================================
  # FALLBACK
  # ============================================================

  def despachar(solicitud) do
    {:error, {:operacion_desconocida, elem(solicitud, 0)}}
  end

  # ============================================================
  # SERIALIZACIÓN Y FORMATEO
  # ============================================================

  defp serializar_usuario(usuario) do
    %{
      id: usuario.id,
      cedula: usuario.cedula,
      first_name: usuario.first_name,
      second_name: usuario.second_name,
      first_lastname: usuario.first_lastname,
      second_lastname: usuario.second_lastname,
      email: usuario.email,
      rol: usuario.rol
    }
  end

  defp serializar_sorteo(sorteo) do
    Map.from_struct(sorteo)
    |> Map.drop([:__meta__, :usuario, :billetes, :notificaciones])
    |> Map.update(:premios, [], fn
      premios when is_list(premios) -> Enum.map(premios, &serializar_premio/1)
      _ -> []
    end)
  end

  defp serializar_premio(premio) do
    Map.from_struct(premio) |> Map.drop([:__meta__, :sorteo])
  end

  # Convierte el resultado de consultar_clientes_sorteo (mapa con :billete_completo
  # y :fraccion, cada uno lista de registros con :usuario struct) al formato que
  # el menú admin espera: %{completo: [nombres], fracciones: [nombres]}.
  defp formatear_clientes(agrupados) do
    completos = Map.get(agrupados, :billete_completo, [])
    fracciones = Map.get(agrupados, :fraccion, [])

    %{
      completo: Enum.map(completos, &nombre_completo(&1.usuario)),
      fracciones: Enum.map(fracciones, &nombre_completo(&1.usuario))
    }
  end

  defp nombre_completo(usuario) do
    [usuario.first_name, usuario.first_lastname]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Convierte el balance global al formato del menú: %{por_sorteo: [...], total_acumulado}
  defp formatear_balance_global(%{sorteos: detalles, total_acumulado: total}) do
    por_sorteo =
      Enum.map(detalles, fn d ->
        %{nombre: d.sorteo.nombre, resultado: d.balance}
      end)

    %{por_sorteo: por_sorteo, total_acumulado: total}
  end

  # Construye el reporte de premios entregados agrupado por sorteo cerrado.
  defp formatear_premios_entregados do
    SorteosC.consultar_premios_entregados()
    |> Enum.group_by(& &1.sorteo.id)
    |> Enum.map(fn {_sorteo_id, premios} ->
      sorteo = hd(premios).sorteo

      %{
        nombre: sorteo.nombre,
        fecha: sorteo.fecha_juego,
        dinero_recolectado: SorteosC.consultar_ingresos(sorteo.id),
        total_premios_entregados:
          Enum.reduce(premios, Decimal.new(0), fn p, acc -> Decimal.add(acc, p.valor) end),
        ganadores: SorteosC.obtener_ganadores_sorteo(sorteo.id)
      }
    end)
  end

  # Agrupa los premios por sorteo para el menú de listar premios del admin.
  defp premios_agrupados_por_sorteo do
    SorteosC.listar_premios()
    |> Enum.group_by(& &1.sorteo.id)
    |> Enum.map(fn {_id, premios} ->
      sorteo = hd(premios).sorteo

      %{
        id: sorteo.id,
        nombre: sorteo.nombre,
        fecha: sorteo.fecha_juego,
        premios:
          Enum.map(premios, fn p ->
            %{id: p.id, nombre: p.nombre, valor: p.valor, estado: p.estado}
          end)
      }
    end)
  end
end
