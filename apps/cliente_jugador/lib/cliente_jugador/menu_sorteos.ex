defmodule ClienteJugador.MenuSorteos do
  @moduledoc "Menú de exploración de sorteos y compras."

  alias ClienteJugador.{Entrada, Cliente, UI}

  def iniciar(sesion) do
    UI.titulo("Sorteos y compras")
    UI.opcion(1, "Ver sorteos disponibles")
    UI.opcion(2, "Consultar números disponibles de un sorteo")
    UI.opcion(3, "Comprar billete completo")
    UI.opcion(4, "Comprar fracciones")
    UI.opcion(5, "Volver al menú principal")

    case Entrada.leer_opcion("Opción: ", [1, 2, 3, 4, 5]) do
      1 -> ver_sorteos(); iniciar(sesion)
      2 -> consultar_numeros(); iniciar(sesion)
      3 -> comprar_completo(sesion); iniciar(sesion)
      4 -> comprar_fracciones(sesion); iniciar(sesion)
      5 -> :ok
    end
  end

  defp ver_sorteos do
    UI.titulo("Sorteos disponibles")

    case Cliente.enviar_solicitud(:listar_sorteos_disponibles, %{}) do
      {:ok, []} -> UI.aviso("No hay sorteos disponibles en este momento.")
      {:ok, sorteos} when is_list(sorteos) ->
        Enum.each(sorteos, fn s ->
          UI.info("\n▸ #{s[:nombre]} (#{s[:fecha]})")
          UI.info("  ID: #{s[:id]}")
          UI.info("  Valor billete completo: $#{s[:valor_billete]}")
          UI.info("  Fracciones por billete: #{s[:num_fracciones]}")
          UI.info("  Cantidad de billetes: #{s[:num_billetes]}")
        end)
      {:error, motivo} -> UI.error("Error: #{inspect(motivo)}")
    end
  end

  defp consultar_numeros do
    UI.titulo("Números disponibles")
    id = Entrada.leer_entero("ID del sorteo: ")

    case Cliente.enviar_solicitud(:consultar_numeros_disponibles, %{sorteo_id: id}) do
      {:ok, %{billetes_completos: completos, fracciones_por_billete: fracciones}} ->
        UI.info("\nBilletes completos disponibles:")
        if completos == [] do
          UI.aviso("  (Ninguno)")
        else
          Enum.each(completos, fn n -> UI.info("  • #{n}") end)
        end

        UI.info("\nFracciones disponibles por billete:")
        Enum.each(fracciones, fn {numero, cant} ->
          if cant > 0, do: UI.info("  • Billete #{numero}: #{cant} fracciones")
        end)

      {:error, motivo} -> UI.error("Error: #{inspect(motivo)}")
    end
  end

  defp comprar_completo(sesion) do
    UI.titulo("Comprar billete completo")

    datos = %{
      jugador_id: sesion.id,
      sorteo_id: Entrada.leer_entero("ID del sorteo: "),
      numero_billete: Entrada.leer_entero("Número del billete: ")
    }

    case Cliente.enviar_solicitud(:comprar_billete_completo, datos) do
      {:ok, compra} ->
        UI.exito("Compra realizada.")
        UI.info("  ID de compra: #{compra[:compra_id]}")
        UI.info("  Billete: #{compra[:numero]}")
        UI.info("  Total pagado: $#{compra[:total]}")

      {:error, :billete_no_disponible} ->
        UI.error("Ese billete ya no está disponible.")

      {:error, motivo} ->
        UI.error("No se pudo completar la compra: #{inspect(motivo)}")
    end
  end

  defp comprar_fracciones(sesion) do
    UI.titulo("Comprar fracciones")

    datos = %{
      jugador_id: sesion.id,
      sorteo_id: Entrada.leer_entero("ID del sorteo: "),
      numero_billete: Entrada.leer_entero("Número del billete: "),
      cant_fracciones: Entrada.leer_entero("Cantidad de fracciones: ")
    }

    case Cliente.enviar_solicitud(:comprar_fracciones, datos) do
      {:ok, compra} ->
        UI.exito("Compra realizada.")
        UI.info("  ID de compra: #{compra[:compra_id]}")
        UI.info("  Billete: #{compra[:numero]}, fracciones: #{compra[:cant_fracciones]}")
        UI.info("  Total pagado: $#{compra[:total]}")

      {:error, :fracciones_insuficientes} ->
        UI.error("No hay tantas fracciones disponibles para ese billete.")

      {:error, motivo} ->
        UI.error("No se pudo completar la compra: #{inspect(motivo)}")
    end
  end
end
