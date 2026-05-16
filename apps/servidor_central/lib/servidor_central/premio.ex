defmodule ServidorCentral.Premio do
  use Ecto.Schema
  import Ecto.Changeset

  @estados ["POR_JUGAR", "ENTREGADO", "PENDIENTE", "SIN_GANADOR"]

  schema "premios" do
    belongs_to(:sorteo, ServidorCentral.Sorteo)
    field(:nombre, :string)
    field(:valor, :decimal)
    field(:numero_ganador, :integer)
    field(:estado, :string, default: "POR_JUGAR")
  end

  def changeset(premio, params \\ %{}) do
    premio
    |> cast(params, [:sorteo_id, :nombre, :valor, :numero_ganador, :estado])
    |> validate_required([:sorteo_id, :nombre, :valor])
    |> validate_inclusion(:estado, @estados)
    |> foreign_key_constraint(:sorteo_id)
  end
end
