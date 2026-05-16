defmodule Azar1.Repo.Migrations.CreatePersona do
  use Ecto.Migration

  def change do
    create table(:persona) do
      add :first_name, :string
      add :last_name, :string
      add :age, :integer
    end
  end
end
