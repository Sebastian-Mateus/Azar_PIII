defmodule Azar1.Repo.Migrations.CrearUsuarios do
  use Ecto.Migration

  def change do
    create table(:usuarios) do
      add :cedula, :string, null: false
      add :first_name, :string, null: false
      add :second_name, :string, null: false
      add :first_lastname, :string, null: false
      add :second_lastname, :string
      add :email, :string, null: false
      add :password_hash, :string, null: false

    end
    create unique_index(:usuarios, [:cedula])
    create unique_index(:usuarios, [:email])
  end

end
