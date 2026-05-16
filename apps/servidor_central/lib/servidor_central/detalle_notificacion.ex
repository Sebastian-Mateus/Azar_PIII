defmodule ServidorCentral.DetalleNotificacion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "detalle_notificaciones" do
    belongs_to(:notificacion, ServidorCentral.Notificacion, primary_key: true)
    belongs_to(:usuario, ServidorCentral.Usuario, primary_key: true)
    field(:estado, :string, default: "NO_LEIDA")
  end

  def changeset(detalle, params \\ %{}) do
    detalle
    |> cast(params, [:notificacion_id, :usuario_id, :estado])
    |> validate_required([:notificacion_id, :usuario_id])
    |> validate_inclusion(:estado, ["LEIDA", "NO_LEIDA"])
    |> foreign_key_constraint(:notificacion_id)
    |> foreign_key_constraint(:usuario_id)
  end
end
