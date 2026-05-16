defmodule Azar1.Repo.Migrations.CreateSorteos do
  use Ecto.Migration

  def change do
    create table(:sorteos) do
      add :usuario_id, references(:usuarios, on_delete: :nilify_all)
      add :nombre, :string, null: false
      add :estado, :string, null: false
      add :valor_billete, :decimal, null: false
      add :num_fracciones, :integer, null: false
      add :num_billetes, :integer, null: false
      add :fecha_juego, :date, null: false
    end
  end
end
