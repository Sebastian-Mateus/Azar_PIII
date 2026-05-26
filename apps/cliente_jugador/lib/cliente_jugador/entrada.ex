defmodule ClienteJugador.Entrada do
  @moduledoc "Lectura y validación de entrada por teclado."

  def leer_texto(mensaje) do
    case IO.gets(mensaje) |> String.trim() do
      "" ->
        IO.puts(" El valor no puede estar vacío.")
        leer_texto(mensaje)

      texto ->
        texto
    end
  end

  def leer_texto_opcional(mensaje) do
    case IO.gets(mensaje) |> String.trim() do
      "" -> nil
      texto -> texto
    end
  end

  def leer_entero(mensaje) do
    case Integer.parse(IO.gets(mensaje) |> String.trim()) do
      {numero, ""} ->
        numero

      _ ->
        IO.puts(" Debe ingresar un número entero válido.")
        leer_entero(mensaje)
    end
  end

  def leer_decimal(mensaje) do
    case Float.parse(IO.gets(mensaje) |> String.trim()) do
      {numero, ""} ->
        numero

      _ ->
        IO.puts(" Debe ingresar un número decimal válido.")
        leer_decimal(mensaje)
    end
  end

  def leer_opcion(mensaje, opciones_validas) do
    case Integer.parse(IO.gets(mensaje) |> String.trim()) do
      {numero, ""} ->
        if numero in opciones_validas do
          numero
        else
          IO.puts(" Opción no válida. Elija una de: #{Enum.join(opciones_validas, ", ")}.")
          leer_opcion(mensaje, opciones_validas)
        end

      _ ->
        IO.puts("Debe ingresar un número.")
        leer_opcion(mensaje, opciones_validas)
    end
  end

  def leer_email(mensaje) do
    entrada = IO.gets(mensaje) |> String.trim()

    if String.contains?(entrada, "@") and String.contains?(entrada, ".") do
      entrada
    else
      IO.puts(" Email inválido.")
      leer_email(mensaje)
    end
  end

  def leer_cedula(mensaje) do
    entrada = IO.gets(mensaje) |> String.trim()

    case Integer.parse(entrada) do
      {_, ""} when byte_size(entrada) >= 6 and byte_size(entrada) <= 12 ->
        entrada

      _ ->
        IO.puts("Cédula inválida (debe ser numérica, 6-12 dígitos).")
        leer_cedula(mensaje)
    end
  end

  def leer_numero_tarjeta(mensaje) do
    entrada = IO.gets(mensaje) |> String.trim() |> String.replace(" ", "")

    case Integer.parse(entrada) do
      {_, ""} when byte_size(entrada) == 16 ->
        entrada

      _ ->
        IO.puts("Número de tarjeta inválido (debe tener 16 dígitos).")
        leer_numero_tarjeta(mensaje)
    end
  end

  def leer_cvc(mensaje) do
    entrada = IO.gets(mensaje) |> String.trim()

    case Integer.parse(entrada) do
      {_, ""} when byte_size(entrada) == 3 ->
        entrada

      _ ->
        IO.puts("CVC inválido (debe tener 3 dígitos).")
        leer_cvc(mensaje)
    end
  end
end
