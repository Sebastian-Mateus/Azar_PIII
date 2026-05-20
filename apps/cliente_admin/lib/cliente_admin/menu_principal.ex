defmodule ClienteAdmin.MenuPrincipal do
  @moduledoc """
  Menú principal del administrador. Se invoca tras autenticación exitosa.
  """

  alias ClienteAdmin.{Entrada, Cliente, UI, MenuSorteos, MenuPremios, MenuReportes}

  def iniciar(sesion) do
    UI.titulo("Menú principal (admin: #{sesion.first_name})")
    UI.opcion(1, "Gestionar sorteos")
    UI.opcion(2, "Gestionar premios")
    UI.opcion(3, "Consultar reportes")
    UI.opcion(4, "Actualizar fecha del sistema")
    UI.opcion(5, "Cerrar sesión")

    case Entrada.leer_opcion("Opción: ", [1, 2, 3, 4, 5]) do
      1 ->
        MenuSorteos.iniciar(sesion)
        iniciar(sesion)

      2 ->
        MenuPremios.iniciar(sesion)
        iniciar(sesion)

      3 ->
        MenuReportes.iniciar(sesion)
        iniciar(sesion)

      4 ->
        actualizar_fecha_sistema()
        iniciar(sesion)

      5 ->
        UI.info("Sesión cerrada.")
        :ok
    end
  end

  defp actualizar_fecha_sistema do
    UI.titulo("Actualizar fecha del sistema")
    UI.info("Esto ejecutará automáticamente todos los sorteos pendientes hasta la fecha indicada.")

    fecha = Entrada.leer_fecha("Nueva fecha del sistema")

    case Cliente.enviar_solicitud(:actualizar_fecha_sistema, %{nueva_fecha: fecha}) do
      {:ok, %{sorteos_jugados: n}} when n > 0 ->
        UI.exito("Fecha actualizada. Se ejecutaron #{n} sorteo(s).")

      {:ok, %{sorteos_jugados: 0}} ->
        UI.exito("Fecha actualizada. No había sorteos pendientes.")

      {:error, :fecha_anterior_actual} ->
        UI.error("La nueva fecha no puede ser anterior a la fecha actual del sistema.")

      {:error, motivo} ->
        UI.error("No se pudo actualizar: #{inspect(motivo)}")
    end
  end
end
