defmodule Azar1.Repo.Migrations.CreateNotificaciones do
  use Ecto.Migration

  def change do
  create table(:notificaciones) do
    add :sorteo_id, references(:sorteos, on_delete: :delete_all), null: false
    add :mensaje, :string, null: false
    add :fecha, :date, null: false
  end

  create index(:notificaciones, [:sorteo_id])
end
end
