defmodule Azar1.Repo.Migrations.CreateDetalleNotificaciones do
  use Ecto.Migration

  def change do
  create table(:detalle_notificaciones, primary_key: false) do
    add :notificacion_id, references(:notificaciones, on_delete: :delete_all), null: false, primary_key: true
    add :usuario_id, references(:usuarios, on_delete: :delete_all), null: false, primary_key: true
    add :estado, :string, default: "NO_LEIDA"
  end
end
end
