defmodule ClienteJugador.UI do
  @moduledoc "Funciones de presentación con color."

  def titulo(texto), do: IO.puts(IO.ANSI.format([:cyan, :bright, "\n=== ", texto, " ===\n"]))
  def exito(texto), do: IO.puts(IO.ANSI.format([:green, "✓ ", texto]))
  def error(texto), do: IO.puts(IO.ANSI.format([:red, "✗ ", texto]))
  def aviso(texto), do: IO.puts(IO.ANSI.format([:yellow, "⚠ ", texto]))
  def info(texto), do: IO.puts(IO.ANSI.format([:light_cyan, texto]))

  def opcion(numero, texto) do
    IO.puts(IO.ANSI.format([:white, "  #{numero}. ", :light_blue, texto]))
  end
end
