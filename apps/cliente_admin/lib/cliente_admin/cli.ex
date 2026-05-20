defmodule ClienteAdmin.CLI do
  @moduledoc """
  Punto de entrada manual del cliente administrador.
  Se invoca desde iex con: ClienteAdmin.CLI.start()
  """

  def start do
    IO.puts("""
    ============================================
       Sistema Azar S.A. — Cliente Administrador
    ============================================
    """)

    ClienteAdmin.MenuLogin.iniciar()
  end
end
