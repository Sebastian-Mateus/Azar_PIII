defmodule ClienteAdmin.Entrada do
  @moduledoc """
  Funciones de lectura y validación de entrada por teclado.
  Cada función pregunta hasta obtener una entrada válida.
  """

  def leer_texto(mensaje) do
    entrada = IO.gets(mensaje) |> String.trim()

    case entrada do
      "" ->
        IO.puts("⚠ El valor no puede estar vacío.")
        leer_texto(mensaje)

      texto ->
        texto
    end
  end

  def leer_entero(mensaje) do
    entrada = IO.gets(mensaje) |> String.trim()

    case Integer.parse(entrada) do
      {numero, ""} ->
        numero

      _ ->
        IO.puts("⚠ Debe ingresar un número entero válido.")
        leer_entero(mensaje)
    end
  end

  def leer_decimal(mensaje) do
    entrada = IO.gets(mensaje) |> String.trim()

    case Float.parse(entrada) do
      {numero, ""} ->
        numero

      _ ->
        IO.puts("⚠ Debe ingresar un número decimal válido.")
        leer_decimal(mensaje)
    end
  end

  def leer_fecha(mensaje) do
    entrada = IO.gets(mensaje <> " (YYYY-MM-DD): ") |> String.trim()

    case Date.from_iso8601(entrada) do
      {:ok, fecha} ->
        fecha

      {:error, _} ->
        IO.puts("Formato inválido. Use YYYY-MM-DD (ejemplo: 2026-05-20).")
        leer_fecha(mensaje)
    end
  end

  def leer_opcion(mensaje, opciones_validas) do
    entrada = IO.gets(mensaje) |> String.trim()

    case Integer.parse(entrada) do
      {numero, ""} ->
        if numero in opciones_validas do
          numero
        else
          IO.puts("⚠ Opción no válida. Elija una de: #{Enum.join(opciones_validas, ", ")}.")
          leer_opcion(mensaje, opciones_validas)
        end

      _ ->
        IO.puts("⚠ Debe ingresar un número.")
        leer_opcion(mensaje, opciones_validas)
    end
  end
end
