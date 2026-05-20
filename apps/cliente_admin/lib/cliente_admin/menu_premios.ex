defmodule ClienteAdmin.MenuPremios do
  @moduledoc """
  Submenú de gestión de premios para administradores.
  """

  alias ClienteAdmin.{Entrada, Cliente, UI}

  def iniciar(sesion) do
    UI.titulo("Gestión de premios")
    UI.opcion(1, "Crear premio para un sorteo")
    UI.opcion(2, "Listar premios (agrupados por sorteo)")
    UI.opcion(3, "Eliminar premio")
    UI.opcion(4, "Volver al menú principal")

    case Entrada.leer_opcion("Opción: ", [1, 2, 3, 4]) do
      1 -> crear_premio(); iniciar(sesion)
      2 -> listar_premios(); iniciar(sesion)
      3 -> eliminar_premio(); iniciar(sesion)
      4 -> :ok
    end
  end

  # ----- Opción 1: Crear premio -----
  defp crear_premio do
    UI.titulo("Crear premio")

    datos = %{
      sorteo_id: Entrada.leer_entero("ID del sorteo: "),
      nombre: Entrada.leer_texto("Nombre del premio: "),
      valor: Entrada.leer_decimal("Valor del premio: ")
    }

    case Cliente.enviar_solicitud(:crear_premio, datos) do
      {:ok, premio} ->
        UI.exito("Premio creado correctamente.")
        UI.info("  ID asignado: #{inspect(premio[:id] || "—")}")

      {:error, :sorteo_no_encontrado} ->
        UI.error("No existe un sorteo con ese ID.")

      {:error, :sorteo_ya_jugado} ->
        UI.error("No se pueden agregar premios a un sorteo ya jugado.")

      {:error, motivo} ->
        UI.error("No se pudo crear el premio: #{inspect(motivo)}")
    end
  end

  # ----- Opción 2: Listar premios agrupados por sorteo -----
  defp listar_premios do
    UI.titulo("Premios registrados (agrupados por sorteo, ordenados por fecha)")

    case Cliente.enviar_solicitud(:listar_premios, %{}) do
      {:ok, []} ->
        UI.aviso("No hay premios registrados.")

      {:ok, sorteos_con_premios} when is_list(sorteos_con_premios) ->
        Enum.each(sorteos_con_premios, &imprimir_sorteo_con_premios/1)

      {:error, motivo} ->
        UI.error("No se pudo obtener la lista: #{inspect(motivo)}")
    end
  end

  defp imprimir_sorteo_con_premios(sorteo) do
    UI.info("\n▸ Sorteo: #{sorteo[:nombre]} (#{sorteo[:fecha]})")

    case sorteo[:premios] do
      [] ->
        UI.aviso("    (sin premios)")

      premios ->
        Enum.each(premios, fn p ->
          UI.info("    • #{p[:nombre]} — $#{p[:valor]}")
        end)
    end
  end

  # ----- Opción 3: Eliminar premio -----
  defp eliminar_premio do
    UI.titulo("Eliminar premio")
    id = Entrada.leer_entero("ID del premio a eliminar: ")

    case Cliente.enviar_solicitud(:eliminar_premio, %{premio_id: id}) do
      {:ok, :eliminado} ->
        UI.exito("Premio eliminado correctamente.")

      {:error, :tiene_clientes} ->
        UI.error("No se puede eliminar: el sorteo del premio ya tiene clientes asociados.")

      {:error, :no_encontrado} ->
        UI.error("No existe un premio con ese ID.")

      {:error, motivo} ->
        UI.error("No se pudo eliminar: #{inspect(motivo)}")
    end
  end
end
