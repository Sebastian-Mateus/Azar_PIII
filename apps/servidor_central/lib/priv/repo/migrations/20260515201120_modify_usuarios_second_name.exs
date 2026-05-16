defmodule Azar1.Repo.Migrations.ModifyUsuariosSecondName do
  use Ecto.Migration

  def change do
alter table(:usuarios) do
      #modify para cambiar la restricción a null: true
      modify :second_name, :string, null: true
    end
  end
end
