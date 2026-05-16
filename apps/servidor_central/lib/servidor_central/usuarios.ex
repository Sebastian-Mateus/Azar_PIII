defmodule ServidorCentral.Usuario do
  @roles_permitidos ["ADMINISTRADOR", "JUGADOR"]
  use Ecto.Schema

  schema "usuarios" do
    field(:cedula, :string)
    field(:rol, :string)
    field(:first_name, :string)
    field(:second_name, :string)
    field(:first_lastname, :string)
    field(:second_lastname, :string)
    field(:email, :string)
    field(:password_hash, :string)

    field(:password, :string, virtual: true)

    has_many(:compras, ServidorCentral.Compra)
    has_many(:cliente_tarjeta, ServidorCentral.ClienteTarjeta)
    has_many(:detalles_notificiaciones, ServidorCentral.DetalleNotificacion)
    has_many(:sorteos, ServidorCentral.Sorteo)
  end

  @doc """
  Changeset para la creación y validacion de usuarios
  """

  def changeset(usuario, params \\ %{}) do
    usuario
    |> Ecto.Changeset.cast(params, [
      :cedula,
      :rol,
      :first_name,
      :second_name,
      :first_lastname,
      :second_lastname,
      :email,
      :password
    ])
    |> Ecto.Changeset.validate_required([
      :cedula,
      :rol,
      :first_name,
      :first_lastname,
      :email,
      :password
    ])
    |> Ecto.Changeset.validate_inclusion(:rol, @roles_permitidos,
      message: "debe ser 'admin' o 'cliente'"
    )
    |> Ecto.Changeset.validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: "debe tener un formato de correo válido"
    )
    |> Ecto.Changeset.unique_constraint(:email)
    |> Ecto.Changeset.unique_constraint(:cedula)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        Ecto.Changeset.put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end
end
