defmodule Azar1.Repo.Migrations.CreatePremios do
  use Ecto.Migration

  def change do
  create table(:premios) do
    add :sorteo_id, references(:sorteos, on_delete: :delete_all), null: false
    add :nombre, :string, null: false
    add :valor, :decimal, null: false
    add :numero_ganador, :integer
    add :estado, :string, default: "POR_JUGAR"
  end

  create index(:premios, [:sorteo_id])
end
end
