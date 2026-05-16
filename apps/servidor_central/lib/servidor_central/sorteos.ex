defmodule ServidorCentral.Sorteo do
  @estados ["PENDIENTE", "JUGADO", "ABIERTO"]
  use Ecto.Schema

  schema "sorteos" do
    belongs_to(:usuario, ServidorCentral.Usuario)
    field(:nombre, :string)
    field(:estado, :string)
    field(:valor_billete, :decimal)
    field(:num_fracciones, :integer)
    field(:num_billetes, :integer)
    field(:fecha_juego, :date)
    has_many(:premios, ServidorCentral.Premio)
    has_many(:billetes, ServidorCentral.Billete)
    has_many(:notificaciones, ServidorCentral.Notificacion)
  end

  @doc """
  Changeset para la creación y validacion de sorteos
  """

  def changeset(sorteo, params \\ %{}) do
    sorteo
    |> Ecto.Changeset.cast(params, [
      :usuario_id,
      :nombre,
      :estado,
      :valor_billete,
      :num_fracciones,
      :num_billetes,
      :fecha_juego
    ])
    |> Ecto.Changeset.validate_required([
      :nombre,
      :estado,
      :valor_billete,
      :num_fracciones,
      :num_billetes,
      :fecha_juego
    ])
    |> Ecto.Changeset.validate_inclusion(:estado, @estados)
  end
end
