defmodule Azar1.Repo.Migrations.CreateBilletes do
  use Ecto.Migration


def change do
  create table(:billetes, primary_key: false) do
    add :numero, :integer, primary_key: true
    add :sorteo_id, references(:sorteos, on_delete: :delete_all), primary_key: true
    add :fracciones_disponibles, :integer, null: false
  end
end

end
