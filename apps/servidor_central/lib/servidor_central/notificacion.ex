defmodule ServidorCentral.Notificacion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notificaciones" do
    belongs_to(:sorteo, ServidorCentral.Sorteo)
    field(:mensaje, :string)
    field(:fecha, :date)

    has_many(:detalle_notificaciones, ServidorCentral.DetalleNotificacion)
  end

  def changeset(notificacion, params \\ %{}) do
    notificacion
    |> cast(params, [:sorteo_id, :mensaje, :fecha])
    |> validate_required([:sorteo_id, :mensaje, :fecha])
    |> foreign_key_constraint(:sorteo_id)
  end
end
