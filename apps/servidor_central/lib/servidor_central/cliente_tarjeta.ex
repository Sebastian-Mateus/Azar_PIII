defmodule ServidorCentral.ClienteTarjeta do
  use Ecto.Schema
  import Ecto.Changeset

  # el struct no tiene un campo :id simple
  @primary_key false
  schema "cliente_tarjeta" do
    belongs_to(:usuario, ServidorCentral.Usuario, primary_key: true)
    belongs_to(:tarjeta, ServidorCentral.Tarjeta, primary_key: true)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:usuario_id, :tarjeta_id])
    |> validate_required([:usuario_id, :tarjeta_id])
    |> unique_constraint([:usuario_id, :tarjeta_id], name: :cliente_tarjeta_pkey)
  end
end
