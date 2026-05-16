defmodule ServidorCentral.Compra do
  use Ecto.Schema
  import Ecto.Changeset

  schema "compras" do
    belongs_to(:usuario, ServidorCentral.Usuario)
    field(:fecha, :date)
    field(:total, :decimal)

    has_many(:detalle_compra, ServidorCentral.DetalleCompra)
  end

  def changeset(compra, params \\ %{}) do
    compra
    |> cast(params, [:usuario_id, :fecha, :total])
    |> validate_required([:usuario_id, :fecha, :total])
    |> foreign_key_constraint(:usuario_id)
  end
end
