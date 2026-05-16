defmodule ServidorCentral.Billete do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "billetes" do
    field(:numero, :integer, primary_key: true)
    belongs_to(:sorteo, ServidorCentral.Sorteo, primary_key: true)
    field(:fracciones_disponibles, :integer)
  end

  def changeset(billete, params \\ %{}) do
    billete
    |> cast(params, [:numero, :sorteo_id, :fracciones_disponibles])
    |> validate_required([:numero, :sorteo_id, :fracciones_disponibles])
    |> validate_number(:numero, greater_than_or_equal_to: 0)
    |> validate_number(:fracciones_disponibles, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:sorteo_id)
  end
end
