defmodule ClienteJugador.CLI do
  @moduledoc "Punto de entrada manual del cliente jugador."

  def start do
    IO.puts("""
    ============================================
       Sistema Azar S.A. — Cliente Jugador
    ============================================
    """)

    ClienteJugador.MenuLogin.iniciar()
  end
end
