defmodule ClienteAdmin.Cliente do
  @moduledoc """
  Capa de transporte. Único módulo que comunica con el servidor.

  Hoy: stub local que simula respuestas del servidor.
  Mañana: abre socket TCP y envía solicitudes serializadas.
  """

  # ----- BASE DE DATOS SIMULADA (solo para desarrollo) -----
  @usuarios_simulados [
    %{
      id: 1,
      email: "carlos@correo.com",
      password: "admin123",
      rol: "ADMINISTRADOR",
      first_name: "Carlos",
      first_lastname: "Pérez"
    },
    %{
      id: 2,
      email: "ana@correo.com",
      password: "admin456",
      rol: "ADMINISTRADOR",
      first_name: "Ana",
      first_lastname: "Ramírez"
    },
    %{
      id: 3,
      email: "juan@correo.com",
      password: "jugador123",
      rol: "JUGADOR",
      first_name: "Juan",
      first_lastname: "López"
    }
  ]

  def enviar_solicitud(operacion, datos) do
    case operacion do
      :autenticar ->
        autenticar_simulado(datos)

      # ----- SORTEOS -----
      :crear_sorteo ->
        IO.puts("[STUB] Creando sorteo: #{inspect(datos)}")
        {:ok, %{id: :rand.uniform(1000), nombre: datos.nombre}}

      :listar_sorteos ->
        {:ok, [
          %{id: 1, nombre: "Lotería del Quindío", fecha: "2026-05-25", estado: "ACTIVO"},
          %{id: 2, nombre: "Sorteo de Navidad", fecha: "2026-12-20", estado: "PENDIENTE"},
          %{id: 3, nombre: "Lotería de Año Nuevo", fecha: "2026-01-01", estado: "FINALIZADO"}
        ]}

      :eliminar_sorteo ->
        cond do
          datos.sorteo_id == 1 -> {:error, :tiene_premios}
          datos.sorteo_id == 99 -> {:error, :no_encontrado}
          true -> {:ok, :eliminado}
        end

      :consultar_clientes_sorteo ->
        {:ok, %{
          completo: ["Ana Ramírez", "Carlos Pérez"],
          fracciones: ["Juan López", "María Gómez", "Pedro Silva"]
        }}

      :consultar_ingresos_sorteo ->
        {:ok, 1_250_000}

      # ----- PREMIOS -----
      :crear_premio ->
        cond do
          datos.sorteo_id == 99 -> {:error, :sorteo_no_encontrado}
          datos.sorteo_id == 3 -> {:error, :sorteo_ya_jugado}
          true ->
            IO.puts("[STUB] Creando premio: #{inspect(datos)}")
            {:ok, %{id: :rand.uniform(1000), nombre: datos.nombre, valor: datos.valor}}
        end

      :listar_premios ->
        {:ok, [
          %{
            id: 1,
            nombre: "Lotería del Quindío",
            fecha: "2026-05-25",
            premios: [
              %{id: 10, nombre: "Premio mayor", valor: 5_000_000},
              %{id: 11, nombre: "Segundo premio", valor: 2_000_000}
            ]
          },
          %{
            id: 2,
            nombre: "Sorteo de Navidad",
            fecha: "2026-12-20",
            premios: [
              %{id: 20, nombre: "Premio único", valor: 10_000_000}
            ]
          },
          %{
            id: 3,
            nombre: "Lotería de Año Nuevo",
            fecha: "2026-01-01",
            premios: []
          }
        ]}

      :eliminar_premio ->
        cond do
          datos.premio_id == 10 -> {:error, :tiene_clientes}
          datos.premio_id == 99 -> {:error, :no_encontrado}
          true -> {:ok, :eliminado}
        end

      # ----- REPORTES -----
      :consultar_premios_entregados ->
        {:ok, [
          %{
            nombre: "Lotería de Año Nuevo",
            fecha: "2026-01-01",
            dinero_recolectado: 8_500_000,
            total_premios_entregados: 5_000_000,
            ganadores: [
              %{nombre_ganador: "Juan López", nombre_premio: "Premio mayor"},
              %{nombre_ganador: "María Gómez", nombre_premio: "Segundo premio"}
            ]
          },
          %{
            nombre: "Sorteo de Octubre",
            fecha: "2025-10-15",
            dinero_recolectado: 3_000_000,
            total_premios_entregados: 4_500_000,
            ganadores: [
              %{nombre_ganador: "Pedro Silva", nombre_premio: "Premio único"}
            ]
          }
        ]}

      :consultar_balance_general ->
        {:ok, %{
          por_sorteo: [
            %{nombre: "Lotería de Año Nuevo", resultado: 3_500_000},
            %{nombre: "Sorteo de Octubre", resultado: -1_500_000}
          ],
          total_acumulado: 2_000_000
        }}

      # ----- FECHA DEL SISTEMA -----
      :actualizar_fecha_sistema ->
        cond do
          Date.compare(datos.nueva_fecha, ~D[2026-05-01]) == :lt ->
            {:error, :fecha_anterior_actual}
          true ->
            {:ok, %{sorteos_jugados: :rand.uniform(3)}}
        end

      # ----- FALLBACK (siempre al final) -----
      _ ->
        IO.puts("[STUB] Solicitud enviada: #{operacion} con datos #{inspect(datos)}")
        {:ok, :stub_response}
    end
  end

  defp autenticar_simulado(%{email: email, password: password, tipo_cliente: tipo}) do
    usuario = Enum.find(@usuarios_simulados, fn u ->
      u.email == email and u.password == password
    end)

    cond do
      usuario == nil ->
        {:error, :credenciales_invalidas}

      tipo == :admin and usuario.rol != "ADMINISTRADOR" ->
        {:error, :credenciales_invalidas}

      tipo == :jugador and usuario.rol != "JUGADOR" ->
        {:error, :credenciales_invalidas}

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
