defmodule ClienteJugador.MenuPrincipal do
  @moduledoc "Menú principal del jugador autenticado."

  alias ClienteJugador.{Entrada, UI, MenuSorteos, MenuCuenta}

  def iniciar(sesion) do
    UI.titulo("Menú principal (#{sesion.first_name})")
    UI.opcion(1, "Sorteos y compras")
    UI.opcion(2, "Mi cuenta (historial, premios, balance)")
    UI.opcion(3, "Cerrar sesión")

    case Entrada.leer_opcion("Opción: ", [1, 2, 3]) do
      1 -> MenuSorteos.iniciar(sesion); iniciar(sesion)
      2 -> MenuCuenta.iniciar(sesion); iniciar(sesion)
      3 -> UI.info("Sesión cerrada.")
    end
  end
end
