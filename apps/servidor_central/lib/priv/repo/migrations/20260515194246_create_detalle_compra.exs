defmodule Azar1.Repo.Migrations.CreateDetalleCompra do
  use Ecto.Migration

  def change do
  create table(:detalle_compras, primary_key: false) do
    add :sorteo_id, :integer, null: false, primary_key: true
    add :numero_billete, :integer, null: false, primary_key: true
    add :compra_id, references(:compras, on_delete: :delete_all), null: false, primary_key: true
    add :num_fracciones, :integer, null: false
    add :subtotal, :decimal, null: false
  end

  create index(:detalle_compras, [:compra_id])

  execute(
    "ALTER TABLE detalle_compras ADD CONSTRAINT detalle_compras_billete_fkey FOREIGN KEY (sorteo_id, numero_billete) REFERENCES billetes(sorteo_id, numero)",
    "ALTER TABLE detalle_compras DROP CONSTRAINT detalle_compras_billete_fkey"
  )
end
end
