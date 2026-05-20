defmodule ClienteAdmin.MenuSorteos do
  @moduledoc """
  Submenú de gestión de sorteos para administradores.
  """

  alias ClienteAdmin.{Entrada, Cliente, UI}

  def iniciar(sesion) do
    UI.titulo("Gestión de sorteos")
    UI.opcion(1, "Crear sorteo")
    UI.opcion(2, "Listar sorteos")
    UI.opcion(3, "Eliminar sorteo")
    UI.opcion(4, "Consultar clientes de un sorteo")
    UI.opcion(5, "Consultar ingresos de un sorteo")
    UI.opcion(6, "Volver al menú principal")

    case Entrada.leer_opcion("Opción: ", [1, 2, 3, 4, 5, 6]) do
      1 -> crear_sorteo(sesion); iniciar(sesion)
      2 -> listar_sorteos(); iniciar(sesion)
      3 -> eliminar_sorteo(); iniciar(sesion)
      4 -> consultar_clientes(); iniciar(sesion)
      5 -> consultar_ingresos(); iniciar(sesion)
      6 -> :ok  # retorna sin recursión → vuelve al menú principal
    end
  end

  # ----- Opción 1: Crear sorteo -----
  defp crear_sorteo(sesion) do
    UI.titulo("Crear nuevo sorteo")

    datos = %{
      nombre: Entrada.leer_texto("Nombre del sorteo: "),
      fecha: Entrada.leer_fecha("Fecha del sorteo"),
      valor_billete: Entrada.leer_decimal("Valor del billete completo: "),
      num_fracciones: Entrada.leer_entero("Cantidad de fracciones por billete: "),
      num_billetes: Entrada.leer_entero("Cantidad de billetes: "),
      id_admin: sesion.id
    }

    case Cliente.enviar_solicitud(:crear_sorteo, datos) do
      {:ok, sorteo} ->
        UI.exito("Sorteo creado correctamente.")
        UI.info("  ID asignado: #{inspect(sorteo[:id] || "—")}")

      {:error, motivo} ->
        UI.error("No se pudo crear el sorteo: #{inspect(motivo)}")
    end
  end

  # ----- Opción 2: Listar sorteos -----
  defp listar_sorteos do
    UI.titulo("Sorteos registrados")

    case Cliente.enviar_solicitud(:listar_sorteos, %{}) do
      {:ok, sorteos} when is_list(sorteos) ->
        if sorteos == [] do
          UI.aviso("No hay sorteos registrados.")
        else
          Enum.each(sorteos, &imprimir_sorteo/1)
        end

      {:ok, _} ->
        UI.aviso("Respuesta del servidor en formato inesperado.")

      {:error, motivo} ->
        UI.error("No se pudo obtener la lista: #{inspect(motivo)}")
    end
  end

  defp imprimir_sorteo(s) do
    UI.info("• #{s[:nombre]} (#{s[:fecha]}) — Estado: #{s[:estado]}")
  end

  # ----- Opción 3: Eliminar sorteo -----
  defp eliminar_sorteo do
    UI.titulo("Eliminar sorteo")
    id = Entrada.leer_entero("ID del sorteo a eliminar: ")

    case Cliente.enviar_solicitud(:eliminar_sorteo, %{sorteo_id: id}) do
      {:ok, :eliminado} ->
        UI.exito("Sorteo eliminado correctamente.")

      {:error, :tiene_premios} ->
        UI.error("No se puede eliminar: el sorteo tiene premios asociados.")

      {:error, :no_encontrado} ->
        UI.error("No existe un sorteo con ese ID.")

      {:error, motivo} ->
        UI.error("No se pudo eliminar: #{inspect(motivo)}")
    end
  end

  # ----- Opción 4: Consultar clientes -----
  defp consultar_clientes do
    UI.titulo("Clientes de un sorteo")
    id = Entrada.leer_entero("ID del sorteo: ")

    case Cliente.enviar_solicitud(:consultar_clientes_sorteo, %{sorteo_id: id}) do
      {:ok, %{completo: completos, fracciones: fraccionarios}} ->
        UI.info("\nCompradores de billete completo:")
        if completos == [] do
          UI.aviso("  (Ninguno)")
        else
          Enum.each(completos, fn c -> UI.info("  • #{c}") end)
        end

        UI.info("\nCompradores por fracción:")
        if fraccionarios == [] do
          UI.aviso("  (Ninguno)")
        else
          Enum.each(fraccionarios, fn c -> UI.info("  • #{c}") end)
        end

      {:error, motivo} ->
        UI.error("No se pudo obtener la información: #{inspect(motivo)}")
    end
  end

  # ----- Opción 5: Consultar ingresos -----
  defp consultar_ingresos do
    UI.titulo("Ingresos de un sorteo")
    id = Entrada.leer_entero("ID del sorteo: ")

    case Cliente.enviar_solicitud(:consultar_ingresos_sorteo, %{sorteo_id: id}) do
      {:ok, monto} ->
        UI.exito("Ingresos totales: $#{monto}")

      {:error, motivo} ->
        UI.error("No se pudo calcular: #{inspect(motivo)}")
    end
  end
end
