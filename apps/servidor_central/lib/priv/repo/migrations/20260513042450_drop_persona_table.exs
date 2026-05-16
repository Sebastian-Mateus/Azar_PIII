defmodule Azar1.Repo.Migrations.DropPersonaTable do
  use Ecto.Migration

  def change do
    drop table(:persona)

  end
end
