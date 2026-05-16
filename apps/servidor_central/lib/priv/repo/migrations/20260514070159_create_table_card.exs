defmodule Azar1.Repo.Migrations.CreateTableCard do
  use Ecto.Migration

  def change do
    create table(:tarjetas) do
      add :numero, :string
      add :month, :string
      add :year, :string
      add :cvc, :string
    end

    create unique_index(:tarjetas, [:numero])
  end
end
