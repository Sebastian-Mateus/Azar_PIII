defmodule ClienteJugador.MenuCuenta do
  @moduledoc "Menú de gestión de cuenta del jugador."

  alias ClienteJugador.{Entrada, Cliente, UI}

  def iniciar(sesion) do
    UI.titulo("Mi cuenta")
    UI.opcion(1, "Historial de compras")
    UI.opcion(2, "Devolver una compra")
    UI.opcion(3, "Premios obtenidos")
    UI.opcion(4, "Balance personal")
    UI.opcion(5, "Notificaciones")
    UI.opcion(6, "Volver al menú principal")

    case Entrada.leer_opcion("Opción: ", [1, 2, 3, 4, 5, 6, 7]) do
      1 ->
        historial(sesion)
        iniciar(sesion)

      2 ->
        devolver(sesion)
        iniciar(sesion)

      3 ->
        premios(sesion)
        iniciar(sesion)

      4 ->
        balance(sesion)
        iniciar(sesion)

      5 ->
        notificaciones(sesion)
        iniciar(sesion)

      6 ->
        agregar_tarjeta(sesion)
        iniciar(sesion)

      7 ->
        :ok
    end
  end

  defp historial(sesion) do
    UI.titulo("Historial de compras")

    case Cliente.enviar_solicitud(:historial_compras, %{jugador_id: sesion.id}) do
      {:ok, %{compras: [], total_gastado: _}} ->
        UI.aviso("No tienes compras registradas.")

      {:ok, %{compras: compras, total_gastado: total}} ->
        Enum.each(compras, fn c ->
          UI.info(
            "• [#{c[:id]}] #{c[:sorteo]} — #{c[:tipo]}, Nº#{c[:numero]} — $#{c[:valor]} (#{c[:fecha]})"
          )
        end)

        UI.info("")
        UI.exito("Total gastado: $#{total}")

      {:error, motivo} ->
        UI.error("Error: #{inspect(motivo)}")
    end
  end

  defp devolver(sesion) do
    UI.titulo("Devolver compra")
    id = Entrada.leer_entero("ID de la compra a devolver: ")

    case Cliente.enviar_solicitud(:devolver_compra, %{jugador_id: sesion.id, compra_id: id}) do
      :ok ->
        UI.exito("Devolución exitosa. La compra fue reversada.")

      {:ok, _} ->
        UI.exito("Devolución exitosa. La compra fue reversada.")

      {:error, :sorteo_ya_cerrado} ->
        UI.error("No se puede devolver: el sorteo ya se realizó.")

      {:error, :compra_no_encontrada} ->
        UI.error("No existe una compra con ese ID.")

      {:error, motivo} ->
        UI.error("No se pudo devolver: #{inspect(motivo)}")
    end
  end

  defp agregar_tarjeta(sesion) do
    UI.titulo("Agregar tarjeta de crédito")

    tarjeta = %{
      "numero" => Entrada.leer_numero_tarjeta("Número de tarjeta (16 dígitos): "),
      "fecha_vencimiento" => Entrada.leer_texto("Fecha de vencimiento (MM/YY): "),
      "cvc" => Entrada.leer_cvc("CVC (3 dígitos): ")
    }

    case Cliente.enviar_solicitud(:agregar_tarjeta, %{usuario_id: sesion.id, tarjeta: tarjeta}) do
      {:ok, _} -> UI.exito("Tarjeta registrada correctamente.")
      {:error, motivo} -> UI.error("No se pudo registrar la tarjeta: #{inspect(motivo)}")
    end
  end

  defp premios(sesion) do
    UI.titulo("Premios obtenidos")

    case Cliente.enviar_solicitud(:premios_obtenidos, %{jugador_id: sesion.id}) do
      {:ok, []} ->
        UI.aviso("Aún no has ganado premios.")

      {:ok, premios} when is_list(premios) ->
        Enum.each(premios, fn p ->
          UI.info(
            "• #{p[:sorteo]} — #{p[:premio]} — ganaste $#{p[:monto_ganado]} (premio total $#{p[:valor_premio]})"
          )
        end)

      {:error, motivo} ->
        UI.error("Error: #{inspect(motivo)}")
    end
  end

  defp balance(sesion) do
    UI.titulo("Balance personal")

    case Cliente.enviar_solicitud(:balance_personal, %{jugador_id: sesion.id}) do
      {:ok, %{total_gastado: g, total_ganado: ga, balance: b}} ->
        UI.info("Total gastado: $#{g}")
        UI.info("Total ganado:  $#{ga}")

        if Decimal.compare(b, Decimal.new(0)) != :lt do
          UI.exito("Balance: +$#{b}")
        else
          UI.error("Balance: -$#{Decimal.abs(b)}")
        end

      {:error, motivo} ->
        UI.error("Error: #{inspect(motivo)}")
    end
  end

  defp notificaciones(sesion) do
    UI.titulo("Notificaciones")

    case Cliente.enviar_solicitud(:notificaciones, %{jugador_id: sesion.id}) do
      {:ok, []} ->
        UI.aviso("No tienes notificaciones.")

      {:ok, notifs} when is_list(notifs) ->
        Enum.each(notifs, fn n ->
          estado = if n[:estado] == "NO_LEIDA", do: "•", else: " "
          UI.info("#{estado} [#{n[:fecha]}] #{n[:mensaje]}")
        end)

      {:error, motivo} ->
        UI.error("Error: #{inspect(motivo)}")
    end
  end
end
