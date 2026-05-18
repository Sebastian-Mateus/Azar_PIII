defmodule ClienteJugador.Cliente do
  @moduledoc "Capa de transporte. Stub para desarrollo del cliente jugador."

  @usuarios_simulados [
    %{
      id: 3,
      email: "juan@correo.com",
      password: "jugador123",
      rol: "JUGADOR",
      first_name: "Juan",
      first_lastname: "López"
    },
    %{
      id: 4,
      email: "maria@correo.com",
      password: "jugador456",
      rol: "JUGADOR",
      first_name: "María",
      first_lastname: "Gómez"
    }
  ]

  def enviar_solicitud(operacion, datos) do
    case operacion do
      :autenticar -> autenticar_simulado(datos)

      :registrar_jugador ->
        IO.puts("[STUB] Registrando jugador: #{inspect(datos)}")
        {:ok, %{
          id: :rand.uniform(1000) + 100,
          rol: "JUGADOR",
          first_name: datos.first_name,
          first_lastname: datos.first_lastname
        }}

      :listar_sorteos_disponibles ->
        {:ok, [
          %{id: 1, nombre: "Lotería del Quindío", fecha: "2026-05-25",
            valor_billete: 50_000, num_fracciones: 10, num_billetes: 100},
          %{id: 2, nombre: "Sorteo de Navidad", fecha: "2026-12-20",
            valor_billete: 100_000, num_fracciones: 5, num_billetes: 50}
        ]}

      :consultar_numeros_disponibles ->
        {:ok, %{
          billetes_completos: [1001, 1002, 1003, 1005, 1010],
          fracciones_por_billete: %{
            1001 => 10, 1002 => 7, 1003 => 3, 1004 => 0, 1005 => 10
          }
        }}

      :comprar_billete_completo ->
        cond do
          datos.numero_billete == 1004 -> {:error, :billete_no_disponible}
          true ->
            {:ok, %{
              compra_id: :rand.uniform(10000),
              tipo: :completo,
              numero: datos.numero_billete,
              total: 50_000
            }}
        end

      :comprar_fracciones ->
        cond do
          datos.cant_fracciones > 10 -> {:error, :fracciones_insuficientes}
          true ->
            {:ok, %{
              compra_id: :rand.uniform(10000),
              tipo: :fracciones,
              numero: datos.numero_billete,
              cant_fracciones: datos.cant_fracciones,
              total: 5_000 * datos.cant_fracciones
            }}
        end

      :historial_compras ->
        {:ok, %{
          compras: [
            %{id: 1, sorteo: "Lotería del Quindío", tipo: "Completo",
              numero: 1001, valor: 50_000, fecha: "2026-05-10"},
            %{id: 2, sorteo: "Lotería del Quindío", tipo: "Fracciones (3)",
              numero: 1002, valor: 15_000, fecha: "2026-05-12"}
          ],
          total_gastado: 65_000
        }}

      :devolver_compra ->
        cond do
          datos.compra_id == 99 -> {:error, :sorteo_ya_jugado}
          datos.compra_id == 100 -> {:error, :no_encontrada}
          true -> {:ok, 50_000}
        end

      :premios_obtenidos ->
        {:ok, [
          %{sorteo: "Lotería de Octubre", premio: "Premio mayor", valor: 5_000_000},
          %{sorteo: "Sorteo de Febrero", premio: "Segundo premio", valor: 1_000_000}
        ]}

      :balance_personal ->
        {:ok, %{gastado: 200_000, ganado: 6_000_000, balance: 5_800_000}}

      :notificaciones ->
        {:ok, [
          %{fecha: "2026-05-15", mensaje: "El sorteo Lotería del Quindío ha finalizado."},
          %{fecha: "2026-05-15", mensaje: "¡Felicitaciones! Ganaste el Premio Mayor."}
        ]}

      _ ->
        IO.puts("[STUB] Solicitud: #{operacion} con datos #{inspect(datos)}")
        {:ok, :stub_response}
    end
  end

  defp autenticar_simulado(%{email: email, password: password, tipo_cliente: tipo}) do
    usuario = Enum.find(@usuarios_simulados, fn u ->
      u.email == email and u.password == password
    end)

    cond do
      usuario == nil -> {:error, :credenciales_invalidas}
      tipo == :jugador and usuario.rol != "JUGADOR" -> {:error, :credenciales_invalidas}
      true ->
        sesion = %{
          id: usuario.id,
          rol: usuario.rol,
          first_name: usuario.first_name,
          first_lastname: usuario.first_lastname
        }
        {:ok, sesion}
    end
  end
end
