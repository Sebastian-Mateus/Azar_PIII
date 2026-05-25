defmodule ClienteAdmin.Cliente do
  @moduledoc """
  Capa de transporte y traducción de contrato para el administrador.
  Traduce las operaciones de los menús al protocolo que espera el servidor
  y adapta las respuestas al formato que los menús esperan.
  """

  alias ClienteAdmin.ClienteTCP

  def enviar_solicitud(operacion, datos) do
    {op_servidor, datos_servidor} = traducir_solicitud(operacion, datos)

    op_servidor
    |> construir_mensaje(datos_servidor)
    |> ClienteTCP.enviar()
    |> traducir_respuesta(operacion)
  end

  # ============================================================
  # TRADUCCIÓN DE SOLICITUDES
  # ============================================================

  defp traducir_solicitud(:autenticar, datos),
    do: {:login, %{email: datos.email, password: datos.password}}

  # El menú manda los campos del sorteo sueltos + id_admin.
  # El servidor espera %{usuario_id, datos: %{...con claves string...}}.
  defp traducir_solicitud(:crear_sorteo, datos) do
    payload = %{
      usuario_id: datos.id_admin,
      datos: %{
        "nombre" => datos.nombre,
        "estado" => "ABIERTO",
        "valor_billete" => to_string(datos.valor_billete),
        "num_fracciones" => datos.num_fracciones,
        "num_billetes" => datos.num_billetes,
        "fecha_juego" => datos.fecha
      }
    }

    {:crear_sorteo, payload}
  end

  defp traducir_solicitud(:listar_sorteos, _datos),
    do: {:listar_sorteos, %{}}

  defp traducir_solicitud(:eliminar_sorteo, datos),
    do: {:eliminar_sorteo, %{id: datos.sorteo_id}}

  defp traducir_solicitud(:consultar_clientes_sorteo, datos),
    do: {:consultar_clientes_sorteo, %{sorteo_id: datos.sorteo_id}}

  defp traducir_solicitud(:consultar_ingresos_sorteo, datos),
    do: {:consultar_ingresos, %{sorteo_id: datos.sorteo_id}}

  # Premios
  defp traducir_solicitud(:crear_premio, datos) do
    payload = %{
      sorteo_id: datos.sorteo_id,
      datos: %{
        "nombre" => datos.nombre,
        "valor" => to_string(datos.valor)
      }
    }

    {:crear_premio, payload}
  end

  defp traducir_solicitud(:listar_premios, _datos),
    do: {:listar_premios, %{}}

  defp traducir_solicitud(:eliminar_premio, datos),
    do: {:eliminar_premio, %{id: datos.premio_id}}

  # Reportes
  defp traducir_solicitud(:consultar_premios_entregados, _datos),
    do: {:consultar_premios_entregados, %{}}

  defp traducir_solicitud(:consultar_balance_general, _datos),
    do: {:consultar_balance_global, %{}}

  # Fecha del sistema
  defp traducir_solicitud(:actualizar_fecha_sistema, datos),
    do: {:actualizar_fecha, %{fecha: datos.nueva_fecha}}

  # Fallback
  defp traducir_solicitud(op, datos), do: {op, datos}

  # ============================================================
  # CONSTRUCCIÓN DEL MENSAJE
  # ============================================================

  defp construir_mensaje(operacion, datos), do: {operacion, datos}

  # ============================================================
  # TRADUCCIÓN DE RESPUESTAS
  # ============================================================

  # crear_sorteo: el servidor devuelve {:ok, %Sorteo{}} ya serializado a mapa.
  # El menú lee sorteo[:id], que ya viene en el mapa. No requiere cambios.

  # eliminar_sorteo: el servidor devuelve {:ok, %Sorteo{}} (el borrado).
  # El menú espera {:ok, :eliminado}.
  defp traducir_respuesta({:ok, _struct}, :eliminar_sorteo), do: {:ok, :eliminado}

  # eliminar_premio: igual que arriba.
  defp traducir_respuesta({:ok, _struct}, :eliminar_premio), do: {:ok, :eliminado}

  # actualizar_fecha: el servidor devuelve {:ok, lista_de_resultados}.
  # El menú espera {:ok, %{sorteos_jugados: n}}.
  defp traducir_respuesta({:ok, lista}, :actualizar_fecha_sistema) when is_list(lista),
    do: {:ok, %{sorteos_jugados: length(lista)}}

  # Por defecto, sin cambios.
  defp traducir_respuesta(respuesta, _operacion), do: respuesta
end
