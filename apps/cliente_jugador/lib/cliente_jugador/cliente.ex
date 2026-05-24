defmodule ClienteJugador.Cliente do
  @moduledoc """
  Capa de transporte y traducción de contrato.
  Traduce las operaciones de los menús al protocolo que espera el servidor,
  y adapta las respuestas al formato que los menús esperan.
  """

  alias ClienteJugador.ClienteTCP

  def enviar_solicitud(operacion, datos) do
    {op_servidor, datos_servidor} = traducir_solicitud(operacion, datos)

    op_servidor
    |> construir_mensaje(datos_servidor)
    |> ClienteTCP.enviar()
    |> traducir_respuesta(operacion)
  end

  # ============================================================
  # TRADUCCIÓN DE SOLICITUDES (nombre menú -> nombre servidor)
  # ============================================================

  defp traducir_solicitud(:autenticar, datos),
    do: {:login, %{email: datos.email, password: datos.password}}

  defp traducir_solicitud(:registrar_jugador, datos),
    do: {:registrar_usuario, aplanar_registro(datos)}

  defp traducir_solicitud(:historial_compras, datos),
    do: {:consultar_historial, %{jugador_id: datos.jugador_id}}

  defp traducir_solicitud(:premios_obtenidos, datos),
    do: {:consultar_premios_obtenidos, %{jugador_id: datos.jugador_id}}

  defp traducir_solicitud(:balance_personal, datos),
    do: {:consultar_balance_personal, %{jugador_id: datos.jugador_id}}

  defp traducir_solicitud(:notificaciones, datos),
    do: {:consultar_notificaciones, %{jugador_id: datos.jugador_id}}

  defp traducir_solicitud(:listar_sorteos_disponibles, _datos),
    do: {:listar_sorteos_abiertos, %{}}

  defp traducir_solicitud(:consultar_disponibilidad_billete, datos),
    do: {:consultar_disponibilidad_billete, %{sorteo_id: datos.sorteo_id, numero: datos.numero}}

  defp traducir_solicitud(:comprar_billete_completo, datos),
    do:
      {:comprar_billete_completo,
       %{
         jugador_id: datos.jugador_id,
         sorteo_id: datos.sorteo_id,
         numero_billete: datos.numero_billete
       }}

  defp traducir_solicitud(:comprar_fracciones, datos),
    do:
      {:comprar_fracciones,
       %{
         jugador_id: datos.jugador_id,
         sorteo_id: datos.sorteo_id,
         numero: datos.numero_billete,
         cantidad: datos.cant_fracciones
       }}

  defp traducir_solicitud(:devolver_compra, datos),
    do: {:devolver_compra, %{compra_id: datos.compra_id}}

  # Fallback: pasa tal cual
  defp traducir_solicitud(op, datos), do: {op, datos}

  # ============================================================
  # CONSTRUCCIÓN DE MENSAJE FINAL
  # ============================================================

  defp construir_mensaje(operacion, datos), do: {operacion, datos}

  # ============================================================
  # TRADUCCIÓN DE RESPUESTAS (formato servidor -> formato menú)
  # ============================================================

  # El servidor ya entrega el historial con los campos correctos (sorteo, tipo,
  # numero, valor, fecha), así que no se transforma: se pasa tal cual.

  # Por defecto, retorna la respuesta tal cual
  defp traducir_respuesta(respuesta, _operacion), do: respuesta

  # ============================================================
  # HELPERS
  # ============================================================

  defp aplanar_registro(datos) do
    %{
      "cedula" => datos.cedula,
      "first_name" => datos.first_name,
      "second_name" => datos.second_name,
      "first_lastname" => datos.first_lastname,
      "second_lastname" => datos.second_lastname,
      "email" => datos.email,
      "password" => datos.password,
      "rol" => "JUGADOR"
    }
  end
end
