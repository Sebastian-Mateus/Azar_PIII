defmodule ClienteAdmin.MenuLogin do
  @moduledoc """
  Menú de autenticación. Pide credenciales hasta lograr login exitoso
  o hasta que el usuario decida salir.
  """

  alias ClienteAdmin.{Entrada, Cliente, MenuPrincipal}

  def iniciar do
    IO.puts("\n=== Iniciar sesión ===")
    IO.puts("1. Iniciar sesión")
    IO.puts("2. Salir")

    case Entrada.leer_opcion("Opción: ", [1, 2]) do
      1 -> autenticar()
      2 -> IO.puts("Hasta luego.")
    end
  end

  defp autenticar do
    email = Entrada.leer_texto("Email: ")
    password = Entrada.leer_texto("Contraseña: ")

    datos = %{email: email, password: password, tipo_cliente: :admin}

    case Cliente.enviar_solicitud(:autenticar, datos) do
      {:ok, %{rol: "ADMINISTRADOR"} = sesion} ->
        IO.puts("\n✓ Bienvenido, #{sesion.first_name} #{sesion.first_lastname}.")
        MenuPrincipal.iniciar(sesion)
        iniciar()

      {:ok, _otro_rol} ->
        IO.puts("\n✗ Esta aplicación es solo para administradores.\n")
        autenticar()

      {:error, _motivo} ->
        IO.puts("\n✗ Credenciales inválidas. Intente nuevamente.\n")
        autenticar()
    end
  end
end
