defmodule ServidorCentral.Tarjeta do
  use Ecto.Schema

  schema "tarjetas" do
    field(:numero, :string)
    field(:fecha_vencimiento, :string)
    field(:cvc, :string)
  end

  def changeset(tarjeta, params \\ %{}) do
    tarjeta
    |> Ecto.Changeset.cast(params, [:numero, :fecha_vencimiento, :cvc])
    |> Ecto.Changeset.validate_format(:numero, ~r/^\d{16}$/, message: "debe tener 16 dígitos")
    |> Ecto.Changeset.validate_format(:fecha_vencimiento, ~r/^\d{2}\/\d{2}$/,
      message: "formato inválido (MM/YY)"
    )
    |> Ecto.Changeset.validate_format(:cvc, ~r/^\d{3,4}$/, message: "debe tener 3 o 4 dígitos")
    |> Ecto.Changeset.unique_constraint(:numero)
  end
end
