defmodule Azar1.Repo.Migrations.UpdateTarjeta do
  use Ecto.Migration

  def change do
    alter table(:tarjetas) do
     remove (:month)
    remove (:year)
    add :fecha_vencimiento, :string
    end

  end
end
