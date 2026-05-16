defmodule Azar1.Repo.Migrations.CreateClienteTarjeta do
  use Ecto.Migration

  def change do
create table(:cliente_tarjeta, primary_key: false) do # Desactivamos el ID automático
      add :usuario_id, references(:usuarios, on_delete: :delete_all), primary_key: true
      add :tarjeta_id, references(:tarjetas, on_delete: :delete_all), primary_key: true
    end
    create index(:cliente_tarjeta, [:tarjeta_id])
  end
end
