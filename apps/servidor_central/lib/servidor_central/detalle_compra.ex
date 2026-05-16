defmodule ServidorCentral.DetalleCompra do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "detalle_compras" do
    field(:sorteo_id, :integer, primary_key: true)
    field(:numero_billete, :integer, primary_key: true)
    belongs_to(:compra, ServidorCentral.Compra, primary_key: true)
    field(:num_fracciones, :integer)
    field(:subtotal, :decimal)
  end

  def changeset(detalle, params \\ %{}) do
    detalle
    |> cast(params, [:sorteo_id, :numero_billete, :compra_id, :num_fracciones, :subtotal])
    |> validate_required([:sorteo_id, :numero_billete, :compra_id, :num_fracciones, :subtotal])
    |> validate_number(:num_fracciones, greater_than: 0)
    |> foreign_key_constraint(:compra_id)
  end
end
