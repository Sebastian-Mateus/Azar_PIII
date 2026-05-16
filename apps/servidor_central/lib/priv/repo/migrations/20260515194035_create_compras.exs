defmodule Azar1.Repo.Migrations.CreateCompras do
  use Ecto.Migration

  def change do
  create table(:compras) do
    add :usuario_id, references(:usuarios, on_delete: :restrict), null: false
    add :fecha, :date, null: false
    add :total, :decimal, null: false
  end

  create index(:compras, [:usuario_id])
end
end
