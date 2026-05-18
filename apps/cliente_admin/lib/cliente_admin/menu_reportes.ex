defmodule ClienteAdmin.MenuReportes do
  @moduledoc """
  Submenú de reportes y consultas generales para administradores.
  """

  alias ClienteAdmin.{Entrada, Cliente, UI}

  def iniciar(sesion) do
    UI.titulo("Reportes y consultas")
    UI.opcion(1, "Premios entregados en sorteos pasados")
    UI.opcion(2, "Balance general de todos los sorteos")
    UI.opcion(3, "Volver al menú principal")

    case Entrada.leer_opcion("Opción: ", [1, 2, 3]) do
      1 -> premios_entregados(); iniciar(sesion)
      2 -> balance_general(); iniciar(sesion)
      3 -> :ok
    end
  end

  # ----- Opción 1: Premios entregados -----
  defp premios_entregados do
    UI.titulo("Premios entregados (sorteos pasados)")

    case Cliente.enviar_solicitud(:consultar_premios_entregados, %{}) do
      {:ok, []} ->
        UI.aviso("Aún no hay sorteos finalizados.")

      {:ok, sorteos} when is_list(sorteos) ->
        Enum.each(sorteos, &imprimir_resumen_sorteo/1)

      {:error, motivo} ->
        UI.error("No se pudo generar el reporte: #{inspect(motivo)}")
    end
  end

  defp imprimir_resumen_sorteo(s) do
    UI.info("\n▸ #{s[:nombre]} (#{s[:fecha]})")
    UI.info("  Dinero recolectado: $#{s[:dinero_recolectado]}")
    UI.info("  Total premios entregados: $#{s[:total_premios_entregados]}")

    resultado = (s[:dinero_recolectado] || 0) - (s[:total_premios_entregados] || 0)

    if resultado >= 0 do
      UI.exito("  Ganancia: $#{resultado}")
    else
      UI.error("  Pérdida: $#{abs(resultado)}")
    end

    UI.info("  Ganadores:")

    case s[:ganadores] do
      [] ->
        UI.aviso("    (sin ganadores)")

      ganadores ->
        Enum.each(ganadores, fn g ->
          UI.info("    • #{g[:nombre_ganador]} — Premio: #{g[:nombre_premio]}")
        end)
    end
  end

  # ----- Opción 2: Balance general -----
  defp balance_general do
    UI.titulo("Balance general")

    case Cliente.enviar_solicitud(:consultar_balance_general, %{}) do
      {:ok, balance} ->
        UI.info("Resumen por sorteo:")

        case balance[:por_sorteo] do
          [] ->
            UI.aviso("  (no hay sorteos finalizados)")

          sorteos ->
            Enum.each(sorteos, fn s ->
              UI.info("  • #{s[:nombre]} → $#{s[:resultado]}")
            end)
        end

        UI.info("")
        total = balance[:total_acumulado] || 0

        if total >= 0 do
          UI.exito("Total acumulado: ganancia de $#{total}")
        else
          UI.error("Total acumulado: pérdida de $#{abs(total)}")
        end

      {:error, motivo} ->
        UI.error("No se pudo generar el balance: #{inspect(motivo)}")
    end
  end
end
