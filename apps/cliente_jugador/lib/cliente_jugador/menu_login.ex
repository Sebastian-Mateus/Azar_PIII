defmodule ClienteJugador.MenuLogin do
  @moduledoc "Menú de login y registro de jugadores."

  alias ClienteJugador.{Entrada, Cliente, UI, MenuPrincipal}

  def iniciar do
    UI.titulo("Bienvenido a Azar S.A. — Jugadores")
    UI.opcion(1, "Iniciar sesión")
    UI.opcion(2, "Registrarse como nuevo jugador")
    UI.opcion(3, "Salir")

    case Entrada.leer_opcion("Opción: ", [1, 2, 3]) do
      1 -> autenticar()
      2 -> registrarse()
      3 -> UI.info("Hasta luego.")
    end
  end

  defp autenticar do
    email = Entrada.leer_email("Email: ")
    password = Entrada.leer_texto("Contraseña: ")

    datos = %{email: email, password: password, tipo_cliente: :jugador}

    case Cliente.enviar_solicitud(:autenticar, datos) do
      {:ok, sesion} ->
        UI.exito("Bienvenido, #{sesion.first_name} #{sesion.first_lastname}.")
        MenuPrincipal.iniciar(sesion)
        iniciar()

      {:error, _} ->
        UI.error("Credenciales inválidas.")
        iniciar()
    end
  end

  defp registrarse do
    UI.titulo("Registro de nuevo jugador")

    datos = %{
      cedula: Entrada.leer_cedula("Cédula: "),
      first_name: Entrada.leer_texto("Primer nombre: "),
      second_name: Entrada.leer_texto_opcional("Segundo nombre: "),
      first_lastname: Entrada.leer_texto("Primer apellido: "),
      second_lastname: Entrada.leer_texto("Segundo apellido: "),
      email: Entrada.leer_email("Email: "),
      password: Entrada.leer_texto("Contraseña: ")
    }

    case Cliente.enviar_solicitud(:registrar_jugador, datos) do
      {:ok, sesion} ->
        UI.exito("Registro completado. Bienvenido, #{sesion.first_name}.")
        MenuPrincipal.iniciar(sesion)

      {:error, motivo} ->
        UI.error("No se pudo registrar: #{inspect(motivo)}")
        iniciar()
    end
  end
end
