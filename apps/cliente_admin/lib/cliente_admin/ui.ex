defmodule ClienteAdmin.UI do
  @moduledoc """
  Funciones de presentación: imprimir mensajes con color y formato.
  """

  def titulo(texto) do
    IO.puts(IO.ANSI.format([:cyan, :bright, "\n=== ", texto, " ===\n"]))
  end

  def exito(texto) do
    IO.puts(IO.ANSI.format([:green, "✓ ", texto]))
  end

  def error(texto) do
    IO.puts(IO.ANSI.format([:red, "✗ ", texto]))
  end

  def aviso(texto) do
    IO.puts(IO.ANSI.format([:yellow, "⚠ ", texto]))
  end

  def opcion(numero, texto) do
    IO.puts(IO.ANSI.format([:white, "  #{numero}. ", :light_blue, texto]))
  end

  def info(texto) do
    IO.puts(IO.ANSI.format([:light_cyan, texto]))
  end
end
