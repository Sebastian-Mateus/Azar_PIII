defmodule Azar1.Repo.Migrations.UpdateUsariosRol do
  use Ecto.Migration

  def change do
    alter table(:usuarios) do
      add :rol, :string
    end

    execute "UPDATE usuarios SET rol = 'admin' WHERE rol is null"

    alter table (:usuarios) do
      modify :rol, :string, null: false

    end
  end
end
